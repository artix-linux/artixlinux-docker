# Docker Base Image for Artix Linux 

This repository contains all scripts and files needed to create a Docker images for the Artix Linux distribution.

## Dependencies

Install the following Artix Linux packages:
* make
* artools
* docker

## Usage

Run `make docker-image` to build the base image.

Run `make docker-image-openrc` to build the openrc image.

Run `make docker-image-runit` to build the runit image.

## Purpose

* Provide Artix Linux in a Docker Image
* Provide the most simple but complete image to base every other upon
* `pacman` needs to work out of the box
* All installed packages have to be kept unmodified
