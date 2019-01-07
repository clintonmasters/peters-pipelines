#!/usr/bin/env bash
# Deploy PKS on vsphere

set -euo pipefail
set -x

declare ssl_certs_json

function generate_cert () (
  set -eu
  local domains="$1"

  local data=$(echo $domains | jq --raw-input -c '{"domains": (. | split(" "))}')

  local response=$(
    om-linux \
      --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "$OPSMAN_USERNAME" \
      --password "$OPSMAN_PASSWORD" \
      --skip-ssl-validation \
      curl \
      --silent \
      --path "/api/v0/certificates/generate" \
      -x POST \
      -d $data
    )

  echo "$response"
)

function SslCertsJson() {
    cert=${1//$'\n'/'\n'}
    key=${2//$'\n'/'\n'}
    local ssl_certs_json="{
        \"cert_pem\": \"$cert\",
        \"private_key_pem\": \"$key\"
    }"
    echo "$ssl_certs_json"
}

function isPopulated() {
    local true=0
    local false=1
    local envVar="${1}"

    if [[ "${envVar}" == "" ]]; then
        return ${false}
    elif [[ "${envVar}" == null ]]; then
        return ${false}
    else
        return ${true}
    fi
}

# PKS API CERT
if [[ "${POE_SSL_NAME1}" == "" || "${POE_SSL_NAME1}" == "null" ]]; then
  domains=(
    "$PKS_API"    
  )

  certificate=$(generate_cert "${domains[*]}")
  pks_api_ssl_cert=`echo $certificate | jq '.certificate'`
  pks_api_ssl_key=`echo $certificate | jq '.key'`
  pks_api_ssl_certs_json="[
    {
      \"name\": \"Certificate 1\",
      \"certificate\": {
        \"cert_pem\": $pks_api_ssl_cert,
        \"private_key_pem\": $pks_api_ssl_key
      }
    }
  ]"
else
    networking_poe_ssl_certs_json=$(formatNetworkingPoeSslCertsJson "${POE_SSL_NAME1}" "${POE_SSL_CERT1}" "${POE_SSL_KEY1}")
    if isPopulated "${POE_SSL_NAME2}"; then
        networking_poe_ssl_certs_json2=$(formatNetworkingPoeSslCertsJson "${POE_SSL_NAME2}" "${POE_SSL_CERT2}" "${POE_SSL_KEY2}")
        networking_poe_ssl_certs_json="$networking_poe_ssl_certs_json,$networking_poe_ssl_certs_json2"
    fi
    if isPopulated "${POE_SSL_NAME3}"; then
        networking_poe_ssl_certs_json3=$(formatNetworkingPoeSslCertsJson "${POE_SSL_NAME3}" "${POE_SSL_CERT3}" "${POE_SSL_KEY3}")
        networking_poe_ssl_certs_json="$networking_poe_ssl_certs_json,$networking_poe_ssl_certs_json3"
    fi
    networking_poe_ssl_certs_json="[$networking_poe_ssl_certs_json]"
fi

# Process Networking seperately since NSX-T section is long.

if [[ "$NSX_NETWORKING_ENABLED" ]]; then

    nsx_pi_certificate="[
    {
        \"cert_pem\": $NSX_PI_CERT,
        \"private_key_pem\": $NSX_PI_KEY
    }
  ]"

else

    nsx_pi_certificate=""

fi

## TODO: Add logic that sets ssl_verification to false if nsx_ca_certificate is not set.  They don't work together


cf_properties=$(
  jq -n \
    --arg vcenter_host "$VCENTER_HOST" \
    --arg vcenter_username "$VCENTER_USR" \
    --arg vcenter_password "$VCENTER_PWD" \
    --arg datacenter "$VCENTER_DATA_CENTER" \
    --arg cluster "$AZ_1_CLUSTER_NAME" \
    --arg pks_api_hostname "$PKS_API" \
    --arg pks_storage_name "$PKS_STORAGE_NAME" \
    --arg nsx_address "$NSX_ADDRESS" \
    --arg nsx_username "$NSX_USERNAME" \
    --arg nsx_password "$NSX_PASSWORD" \
    --arg nsx_ca_certificate "$NSX_CA_CERTIFICATE" \
    --arg nsx-nodes-ip-block-id "$NSX_NODES_IP_BLOCK_ID" \
    --arg nsx-ip-block-id "$NSX_IP_BLOCK_ID" \
    --arg nsx-floating-ip-pool-ids "$NSX_FLOATING_IP_POOL_ID" \
    --arg nsx-t0-router-id "$NSX_TO_ROUTER_ID" \
    --arg dns "$NW_DNS" \
    --arg pks_vms "$PKS_VMS"
    --arg availability_zones "$NW_AZS" \
    --arg container_networking_nw_cidr "$CONTAINER_NETWORKING_NW_CIDR" \
    --argjson nsx-t-superuser-certificate "$nsx_pi_certificate" \
    --argjon pks_api_ssl_certs: "$pks_api_ssl_certs" \
    '
    {
       ".pivotal-container-service.pks_tls": {
            "value": $pks_api_ssl_certs
        }, 
        ".properties.cloud_provider": {
            "value": "vSphere"
        }, 
        ".properties.cloud_provider.vsphere.vcenter_ip": {
            "value": $vcenter_host
        }, 
        ".properties.cloud_provider.vsphere.vcenter_dc": {
            "value": $datacenter
        }, 
        ".properties.network_selector.nsx.vcenter_cluster": {
            "value": $cluster
        },      
        ".properties.cloud_provider.vsphere.vcenter_master_creds": {
            "value": {
                "password": $vcenter_password, 
                "identity": $vcenter_username
            }
        },     
    }
    +
    if $nsx_ca_certificate != ""  then 
    { 
        ".properties.network_selector": {
            "value": "nsx"
        },     
        ".properties.network_selector.nsx.network_automation": {
            "value": true
        }, 
        ".properties.network_selector.nsx.nsx-t-host": {
            "value": $nsx_address
        },
        ".properties.network_selector.nsx.nat_mode": {
            "value": true
        }, 
        ".properties.network_selector.nsx.nsx-t-superuser-certificate": {
            "value": $nsx-t-superuser-certificate
        }, 
        ".properties.network_selector.nsx.nsx-t-insecure": {
            "value": true
        }, 
        ".properties.network_selector.nsx.t0-router-id": {
            "value": $nsx-t0-router-id
        }, 
        ".properties.network_selector.nsx.nodes-ip-block-id": {
            "value": $nsx-nodes-ip-block-id
        }, 
        ".properties.network_selector.nsx.ip-block-id": {
            "value": $nsx-ip-block-id
        }, 
        ".properties.network_selector.nsx.cloud-config-dns": {
            "value": $dns
        },
        ".properties.network_selector.nsx.floating-ip-pool-ids": {
            "value": $nsx-floating-ip-pool-ids
        },
        ".properties.network_selector.nsx.lb_size_medium_supported": {
            "value": true
        }, 
           ".properties.network_selector.nsx.lb_size_large_supported": {
            "value": false
        }, 
    }
    else
    {
        ".properties.network_selector": {
            "value": "flannel"
        },    
    } 
    end
    +
    {  
        ".properties.worker_max_in_flight": {
            "value": 1
        }, 
        ".properties.uaa_oidc": {
            "value": false
        }, 
        ".properties.sink_resources": {
            "value": true
        },   
        ".properties.pks_api_hostname": {
            "value": $pks_api_hostname
        },
        ".properties.cloud_provider.vsphere.vcenter_vms": {
            "value": $pks_vms
        }, 
        ".properties.telemetry_selector.enabled.interval": {
            "value": 600
        }, 
        ".properties.syslog_migration_selector.enabled.transport_protocol": {
            "value": "tcp"
        }, 
        ".properties.proxy_selector.enabled.https_proxy_credentials": {
            "value": {
                "password": "***"
            }
        }, 
        ".properties.telemetry_selector.enabled.telemetry_url": {
            "value": "https://vcsa.vmware.com"
        }, 
        ".properties.pks-vrli": {
            "value": "disabled"
        }, 
        ".properties.proxy_selector": {
            "value": "Disabled"
        }, 
        ".properties.uaa.ldap.external_groups_whitelist": {
            "value": "*"
        }, 
        ".properties.proxy_selector.enabled.http_proxy_credentials": {
            "value": {
                "password": "***"
            }
        }, 
        ".properties.uaa.ldap.ldap_referrals": {
            "value": "follow"
        }, 
        ".properties.telemetry_selector": {
            "value": "disabled"
        }, 
         ".properties.syslog_migration_selector": {
            "value": "disabled"
        }, 
        ".properties.pks-vrli.enabled.skip_cert_verify": {
            "value": false
        }, 
        ".properties.cloud_provider.vsphere.vcenter_ds": {
            "value": $pks_storage_name
        }, 
        ".properties.wavefront": {
            "value": "disabled"
        }, 
        ".properties.plan2_selector.active.allow_privileged_containers": {
            "value": true
        }, 
        ".properties.plan2_selector.active.errand_vm_type": {
            "value": "micro"
        }, 
        ".properties.plan3_selector.active.errand_vm_type": {
            "value": "micro"
        },  
        ".properties.plan1_selector.active.master_instances": {
            "value": 1
        }, 
        ".properties.plan3_selector.active.disable_deny_escalating_exec": {
            "value": false
        }, 
        ".properties.plan1_selector.active.worker_az_placement": {
            "value": ($availability_zones | split(","))
        }, 
        ".properties.plan1_selector.active.master_az_placement": {
            "value": ($availability_zones | split(","))
        }, 
        ".properties.plan2_selector.active.master_az_placement": {
            "value": ($availability_zones | split(","))
        }, 
        ".properties.plan2_selector.active.worker_az_placement": {
            "value": ($availability_zones | split(","))
        },        
        ".properties.plan3_selector.active.master_az_placement": {
            "value": ($availability_zones | split(","))
        }, 
        ".properties.plan3_selector.active.worker_az_placement": {
            "value": ($availability_zones | split(","))
        }, 
        ".properties.plan1_selector.active.disable_deny_escalating_exec": {
            "value": false
        }, 
        ".properties.plan2_selector": {
            "value": "Plan Active"
        }, 
        ".properties.plan2_selector.active.worker_persistent_disk_type": {
            "value": "10240"
        }, 
        ".properties.plan3_selector.active.allow_privileged_containers": {
            "value": false
        }, 
        ".properties.plan2_selector.active.master_instances": {
            "value": 1
        }, 
        ".properties.plan1_selector.active.worker_persistent_disk_type": {
            "value": "10240"
        }, 
        ".properties.plan1_selector.active.description": {
            "value": "Example: This plan will configure a lightweight kubernetes cluster."
        }, 
        ".properties.plan2_selector.active.master_vm_type": {
            "value": "medium"
        }, 
        ".properties.plan1_selector.active.name": {
            "value": "small"
        }, 
        ".properties.plan1_selector.active.master_persistent_disk_type": {
            "value": "10240"
        }, 
        ".properties.plan3_selector.active.master_vm_type": {
            "value": "medium.disk"
        }, 
        ".properties.plan1_selector.active.worker_instances": {
            "value": 3
        }, 
        ".properties.plan3_selector.active.name": {
            "value": "multimaster"
        }, 
        ".properties.plan1_selector": {
            "value": "Plan Active"
        }, 
        ".properties.plan2_selector.active.description": {
            "value": "Example: This plan will configure a privledged kubernetes cluster"
        }, 
        ".properties.plan1_selector.active.errand_vm_type": {
            "value": "micro"
        }, 
        ".properties.plan3_selector.active.description": {
            "value": "plan3"
        }, 
        ".properties.plan2_selector.active.worker_instances": {
            "value": 3
        }, 
        ".properties.plan3_selector": {
            "value": "Plan Active"
        },
        ".properties.plan2_selector.active.master_persistent_disk_type": {
            "value": "10240"
        }, 
        ".properties.syslog_migration_selector.enabled.tls_enabled": {
            "value": true
        }, 
        ".properties.plan3_selector.active.master_instances": {
            "value": 3
        }, 
        ".properties.plan3_selector.active.worker_instances": {
            "value": 1
        }, 
        ".properties.plan3_selector.active.master_persistent_disk_type": {
            "value": "10240"
        },  
        ".properties.plan2_selector.active.name": {
            "value": "privledged"
        }, 
        ".properties.uaa": {
            "value": "internal"
        }, 
        ".properties.plan1_selector.active.master_vm_type": {
            "value": "medium"
        }, 
        ".properties.plan3_selector.active.worker_persistent_disk_type": {
            "value": "51200"
        }, 
        ".properties.plan1_selector.active.worker_vm_type": {
            "value": "medium"
        }, 
        ".properties.plan1_selector.active.allow_privileged_containers": {
            "value": true
        }, 
        ".properties.plan2_selector.active.disable_deny_escalating_exec": {
            "value": false
        }, 
        ".properties.plan3_selector.active.worker_vm_type": {
            "value": "medium.disk"
        }
    }
    '
)

cf_network=$(
  jq -n \
    --arg network_name "$NETWORK_NAME" \
    --arg other_azs "$DEPLOYMENT_NW_AZS" \
    --arg singleton_az "$ERT_SINGLETON_JOB_AZ" \
    '
    {
      "network": {
        "name": $network_name
      },
      "other_availability_zones": ($other_azs | split(",") | map({name: .})),
      "singleton_availability_zone": {
        "name": $singleton_az
      },
      "service_network": {
        "name": $network_name
      }
    }
    '
)

JOB_RESOURCE_CONFIG="{
  \"pivotal-container-service\": { 
      \"instances\": \"automatic\",
      \"persistent_disk\": { \"size_mb\": \"automatic\" },
      \"instance_type\": { \"id\": \"automatic\" }
      }
}"

      
cf_resources=$(
  jq -n \
    --arg iaas "$IAAS" \
        --argjson job_resource_config "${JOB_RESOURCE_CONFIG}" \
    '
    $job_resource_config    
    '
)

om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --username "$OPSMAN_USERNAME" \
  --password "$OPSMAN_PASSWORD" \
  --skip-ssl-validation \
  configure-product \
  --product-name pivotal-container-service \
  --product-properties "$cf_properties" \
  --product-network "$cf_network" \
  --product-resources "$cf_resources"
