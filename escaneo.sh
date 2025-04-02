#!/bin/bash

# Crear carpeta para capturas si no existe
mkdir -p ./screenshot

# Red a escanear
RED="172.233.100.0/24"

# Escaneo con Nmap para encontrar puertos abiertos
echo "Escaneando la red $RED en busca de servicios web..."
nmap -p 80,443,8080,8000,5000,9000,4443,8888 --open -sS -sV $RED -oG nmap_results.txt

# Extraer IPs con servicios web abiertos
cat nmap_results.txt | grep "open" | awk '{print $2}' | sort -u > active_ips.txt

# Revisar si se encontraron IPs activas
if [ ! -s active_ips.txt ]; then
    echo "❌ No se encontraron servidores web en la red."
    exit 1
fi

echo "Se encontraron $(wc -l < active_ips.txt) IPs con servicios web. Tomando capturas..."

# Iterar sobre cada IP encontrada y capturar su web
while read -r ip; do
    echo "📸 Capturando interfaz web en $ip..."

    # Captura HTTP
    gowitness single --url "http://$ip" --destination ./screenshot/ --no-http
    
    # Captura HTTPS
    gowitness single --url "https://$ip" --destination ./screenshot/ --no-http

    # Captura para puertos específicos
    for puerto in 80 443 8080 8000 5000 9000 4443 8888; do
        echo "Intentando capturar $ip:$puerto..."
        gowitness single --url "http://$ip:$puerto" --destination ./screenshot/ --no-http
        gowitness single --url "https://$ip:$puerto" --destination ./screenshot/ --no-http
    done

done < active_ips.txt

echo "✅ Escaneo completado. Capturas guardadas en ./screenshot/"
