version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: host
    deploy:
      mode: global
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    networks:
      - nginx-network

networks:
  nginx-network:
    driver: overlay

