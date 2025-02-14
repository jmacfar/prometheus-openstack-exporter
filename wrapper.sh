#!/bin/sh

prometheusDir='/etc/prometheus'
configFile=${configFile:-"${prometheusDir}/prometheus-openstack-exporter.yaml"}
listenPort=${listenPort:-9183}
cacheRefreshInterval=${cacheRefreshInterval:-300}
cacheFileName=${cacheFileName:-"$(mktemp -p /dev/shm/)"}
cloud=${OS_REGION_NAME:-mycloud}
vcpuRatio=${vcpuRatio:-1.0}
ramRatio=${ramRatio:-1.0}
diskRatio=${diskRatio:-1.0}
enabledCollectors=${enabledCollectors:-cinder neutron nova}
schedulableInstanceRam=${schedulableInstanceRam:-4096}
schedulableInstanceVcpu=${schedulableInstanceVcpu:-2}
schedulableInstanceDisk=${schedulableInstanceDisk:-20}
useNovaVolumes=${useNovaVolumes:-True}
resellerPrefix=${resellerPrefix:-AUTH_}

if [ ! -e "${configFile}" ]; then
    mkdir -p ${prometheusDir}
    cp prometheus-openstack-exporter.sample.yaml ${configFile}
    
    sed -i "s|VAR_LISTEN_PORT|${listenPort}|g" 					${configFile}
    sed -i "s|VAR_CACHE_REFRESH_INTERVAL|${cacheRefreshInterval}|g" 		${configFile}
    sed -i "s|VAR_CACHE_FILE|${cacheFileName}|g" 				${configFile}
    sed -i "s|VAR_CLOUD|${cloud}|g" 						${configFile}
    sed -i "s|VAR_VCPU_RATIO|${vcpuRatio}|g" 					${configFile}
    sed -i "s|VAR_RAM_RATIO|${ramRatio}|g" 					${configFile}
    sed -i "s|VAR_DISK_RATIO|${diskRatio}|g"	 				${configFile}
    sed -i "s|VAR_SCHEDULABLE_INSTANCE_RAM|${schedulableInstanceRam}|g" 	${configFile}
    sed -i "s|VAR_SCHEDULABLE_INSTANCE_VCPU|${schedulableInstanceVcpu}|g" 	${configFile}
    sed -i "s|VAR_SCHEDULABLE_INSTANCE_DISK|${schedulableInstanceDisk}|g" 	${configFile}
    sed -i "s|VAR_USE_NOVA_VOLUMES|${useNovaVolumes}|g" 			${configFile}

    for i in ${enabledCollectors}; do
        sed -i "s/.*VAR_ENABLED_COLLECTORS/  - ${i}\n    - VAR_ENABLED_COLLECTORS/g" 	${configFile}
    done
    sed -i '/.*VAR_ENABLED_COLLECTORS.*/d'					${configFile} 

    for i in ${keystoneTenantsMap}; do
        tenantName=$(echo ${i} | cut -d',' -f1)
        tenantId=$(  echo ${i} | cut -d',' -f2)
        sed -i "s/.*VAR_KEYSTONE_TENANTS_MAP/  - ${tenantName} ${tenantId}\n  - VAR_KEYSTONE_TENANTS_MAP/g" ${configFile}
    done
    
    sed -i 's/VAR_.*//g'		 					${configFile}

    touch ${cacheFileName}

    cat ${configFile}
fi

/prometheus-openstack-exporter ${configFile}

rm ${cacheFileName}

exit 0
