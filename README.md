# Script de diagnóstico de red — Debian 13

Proyecto del curso **Sistemas Operativos** (Ingeniería de Sistemas, Fundación Universitaria Compensar).

Script en Bash que ejecuta `ping`, `traceroute` y `netstat` sobre una lista de hosts y genera un **informe de conectividad** con el estado, la latencia promedio, la pérdida de paquetes y los saltos de cada host. Refuerza conceptos de redes y el manejo de arrays en Bash.

## Integrantes
- Juan José Ardila Moreno
- Juan Esteban Barrero Mur
- Cristian Yesid González Valbuena
- Sebastián Andrés Ramos López

## Estructura del repositorio
```
script-diagnostico-red-debian13/
├── src/
│   ├── diagnostico_red.sh    # Script principal
│   └── hosts.txt             # Lista de hosts de ejemplo
├── tests/
│   └── test_scripts.sh       # Pruebas de sintaxis, permisos y lista de hosts
├── docs/
│   ├── Proyecto_Diagnostico_Red_IEEE.docx   # Documento en formato IEEE
│   └── Presentacion_Diagnostico_Red.pptx    # Presentación de la exposición
├── LICENSE
└── README.md
```

## Entorno
- VMware Workstation Pro 17 (4 GB RAM, 2 CPU, 25 GB de disco, red NAT)
- Debian 13 (Trixie) con KDE Plasma
- Bash 5

## Requisitos
```bash
sudo apt install iputils-ping traceroute net-tools
```

## Uso
```bash
git clone https://github.com/jar90753-create/script-diagnostico-red-debian13.git
cd script-diagnostico-red-debian13
chmod +x src/diagnostico_red.sh tests/test_scripts.sh

./src/diagnostico_red.sh                  # usa la lista de hosts interna
./src/diagnostico_red.sh src/hosts.txt    # lee los hosts desde un archivo
```

El informe se guarda en `~/informes_red/informe_AAAA-MM-DD_HH-MM-SS.txt`.

## Pruebas
```bash
./tests/test_scripts.sh
```
Revisa la sintaxis y los permisos de ejecución de cada script de `src/` y que `hosts.txt` tenga hosts. Muestra `[OK]` o `[FALLO]` por cada comprobación.

## Cómo funciona
1. **Arrays:** la lista de hosts se guarda en un array indexado (`HOSTS`) y los resultados en arrays asociativos (`ESTADO`, `LATENCIA`, `PERDIDA`, `SALTOS`) cuya clave es el nombre del host.
2. **ping:** envía 4 paquetes ICMP a cada host y extrae la latencia promedio y el porcentaje de pérdida.
3. **traceroute:** muestra la ruta hasta cada host activo (máximo 15 saltos).
4. **netstat:** muestra los puertos en escucha, las conexiones TCP establecidas y la tabla de enrutamiento del equipo.
5. **Informe:** todo se muestra en pantalla con colores y se guarda en un archivo de texto, con una tabla resumen al final.

## Resultado de ejemplo
| Host | Estado | Latencia | Pérdida |
|---|---|---|---|
| google.com | ACTIVO | 6.124 ms | 0 % |
| debian.org | ACTIVO | 5.160 ms | 0 % |
| 8.8.8.8 | ACTIVO | 8.669 ms | 0 % |
| 1.1.1.1 | ACTIVO | 52.725 ms | 0 % |
| github.com | ACTIVO | 71.935 ms | 0 % |
| host-inexistente.local | INACTIVO | - | 100 % |

> Nota: con la red NAT de VMware, traceroute (UDP) no recibe respuesta de los routers intermedios y llega al límite de 15 saltos. Con `sudo traceroute -I` (ICMP) o con la red en modo puente se obtiene la ruta real.

## Referencias
- [Guía de referencia de Debian](https://www.debian.org/doc/manuals/debian-reference/index.es.html)
- [Configurar sudo en Debian](https://wiki.debian.org/es/sudo)
- [Proyectos básicos de manejo de terminal — Debian 13](https://github.com/andres-gutierrezri/proyectos-basicos-terminal-debian13) (repositorio del curso)

## Licencia
Distribuido bajo la licencia MIT. Ver [LICENSE](LICENSE).
