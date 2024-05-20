# Тестовое задание Kaspersky TeachBase DevOps 2024

## Задание
Так как задания для всех тестовых команд были практически одинаковые, были сделаны некоторые отступления и выполнено общее задание, которое включает в себя поднятие виртуальной машины и запуск на ней сервисов с помощью Cms и сервисов контейнеризации.

1. В качестве гипервизора 2-го типа разрешается использовать любой, по своему усмотрению: VMware Workstation, VirtualBox, HyperV, Qemu, Vagrant и т.п.
2. Микросервис должен доставляться на виртуальную машину с помощью системы управления конфигурациями, после чего микросервис должен работать в фоне на ВМ. Необходимая CMS (Configuration Management Systems / Система Управления Конфигурациями): Ansible.
3. Микросервис который будет развернут в контейнере не принципиален, для простоты можете развернуть nginx.
4. При старте контейнера конфигурационный файл должен монтироваться внутрь контейнера (Volumes, -v).
5. При старте контейнера должен быть прокинут порт 8080 "наружу" (на виртуальную машину) используя "-p, port".
6. В браузере на виртуальной машине по адресу должны отображаться соответствующие метрики.

### Бонусное задание 1
1. Адаптировать ansible-role и ansible-playbook также под альтернативный сценарий: запуск того же микросервиса в контейнере на той же ВМ.
2. В качестве CRI (Container Runtime Interface) использовать Docker или Podman.
3. Установку докера в ansible-role закидывать необязательно, можно выполнить руками заранее.

### Бонусное задание 2
1. Автоматизировать этап создания виртуальной машины из пункта 1 основного задания. Автоматизация должна включать в себя (1) создание виртуальной машины (2) установку ОС в виртуальной машине (3) настройку ОС в виртуальной машине (до этапа разворачивания микросервиса, но, по возможности, с автоматизацией установки и настройки CRI).
2. В качестве основы для автоматизации создания ВМ можно использовать любые языки программирования либо утилиты для реализации подхода Infrastructure as a Code.

## Быстрая установка
Задание выполнялось на ОС Ubuntu 23.10; Для управления виртуальной машиной используется vagrant, далее все системы управления и контейнеризации по условию. 
```shell
# Install dependencies
sudo apt install -y vagrant ansible virtualbox
# Clone files and configurations
git clone https://github.com/filberol/kaspersky_contest.git kasp
cd kasp
# Initialize and start machine
vagrant up
# Add ssh method and machine to known hosts
chmod +x acknowledge-vm.sh
./acknowledge-vm.sh
# Start ansible task
ansible-playbook -i vm-hosts.yml nginx-docker.yml 
```
После корректной установки, на локальные порты должны прокинуться следующие сервисы:

- http://localhost:8080/ - Сервер Nginx
- http://localhost:3030/ - Инстанс Grafana
- http://localhost:9090/ - Инстанс Prometheus

## Отчет о созданных конфигурациях

### Vagrantfile
Файл конфигурации виртуальной машины для автоматизации запуска и деплоя. Операционная система в данном случае не имеет значения, может быть использована любая из каталога Vagrant Box https://app.vagrantup.com/boxes/search

```shell
Vagrant.configure("2") do |config|
  # Образ виртуальной системы скачивается из удаленного репозитория
  # Это позволяет не держать никаких дополнительных файлов
  config.vm.box = "ubuntu/focal64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-vagrant.box"

  # Порты виртуальной машины, которые необходимо опубликовать на localhost
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3030
  config.vm.network "forwarded_port", guest: 9090, host: 9090

  # Подключение виртуальной машины к локальной сети, для коннекта с Ansible
  config.vm.network "private_network", ip: "192.168.56.10"

  # Не забудем ограничить память, чтобы не тратить ресурсы
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  # --- Здесь приведен набор скриптов для установки docker и docker compose, по условию эти утилиты могут быть предустановлены
  config.vm.provision "shell", inline: <<-SHELL
    ...
  SHELL

  # Также добавим публичный ключ на систему для доступа без пароля
  config.vm.provision "shell" do |s|
    ...
  end
end
```

## Dockerfile
Простой файл сборки, который добавляет страницы и конфигурацию в образ Nginx
```dockerfile
FROM nginx
COPY /etc/nginx/conf.d /etc/nginx/conf.d
COPY *.html /usr/share/nginx/html
EXPOSE 80
```

## Ansible playbook
Файл конфигурации системы, который помещает на машину исходники, собирает образ Nginx и разворачивает набор сервисов посредством docker compose. Он также удостоверяется в наличии необходимых утилит.

```yml
- name: Setup Nginx in Docker
  hosts: nginx_vm
  become: yes
  vars:
    ...
  tasks:
    # Проверка наличия обеспечения
    - name: Ensure Docker is installed
      ...
    - name: Ensure Docker service is running
      ...
    # Пул чистого образа, для оптимизации сборки
    - name: Pull the Nginx Docker image
      ...
    # Создание конфигурации сервера
    - name: Create Nginx configuration directory
      ...
    - name: Copy Nginx configuration files
      ...
    # Копирование необходимых для сборки ресурсов
    - name: Copy sources to build directory
      ...
    # Сборка нового образа
    # Так как образ удаляется, он каждыйз раз пересобирается
    # Для этого тестового задания такой вариант удобен
    - name: Stop the Docker container
      ...
    - name: Build Docker image
      ...
    # Старт серверя и связянных с ним образов для метрик
    - name: Compose services
      ...
```

## Docker compose
В необходимые места образов монтируются папки и конфигурации. Отдельные бд для хранения результатов в данном примере созданы не были. Также всем контейнерам были выданы права суперпользователя, без настройки доступов и безопасности.

```yml
services:
  # Сервер Nginx, конфигурация для него заранее помещена на машину
  # Используется созданный заранее сервис, собранный на этой же машине
  nginx:
    image: nginx_server
    ...
  # Grafana
  grafana:
    image: grafana/grafana:latest
    ...
  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    ...
# Также создана дополнительная виртуальная сеть, посредством которой общаются составители метрик
networks:
  monitoring:
    driver: bridge

```

## Дополнительные конфигурации
Все остальные файлы конфигураций соответствуют таковым по умолчанию для приведенных сервисов.

author: filberol Vadim Mikhu