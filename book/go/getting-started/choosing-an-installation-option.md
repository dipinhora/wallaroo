# Choosing an Installation Option for Wallaroo

For 64-bit MacOS and Windows users, we provide two different ways for you to install Wallaroo:
- [Wallaroo in Docker](/book/go/getting-started/docker-setup.md)
- [Wallaroo in Vagrant](/book/go/getting-started/vagrant-setup.md)

If you are unsure about which solution is right for you, a breakdown of each is provided below. (NOTE: Wallaroo does not support 32-bit platforms.)

For 64-bit Linux users, we provide three different ways for you to install Wallaroo:
- [Wallaroo in Docker](/book/go/getting-started/docker-setup.md)
- [Wallaroo in Vagrant](/book/go/getting-started/vagrant-setup.md)
- [Wallaroo Up](/book/go/getting-started/wallaroo-up.md)
- [Installing from Source](/book/go/getting-started/linux-setup.md)

If you are unsure about which solution is right for you, a breakdown of each is provided below. (NOTE: Wallaroo does not support 32-bit platforms.)

## Installing with Docker

We recommend this process if you're looking to get started quickly and do not rely on a heavily customized environment for development.

Installing with Docker provides the benefit of needing to install only one system dependency: Docker itself. Once Docker is set up, you will only need to run a `docker pull` and you will have Wallaroo and all of its support tools available within the Wallaroo Docker image.

The Docker environment has limited customizability due to the nature of a container's lifecycle but we have provided options to persist code changes for you.

## Installing with Vagrant

We recommend this process if you're looking to get started quickly and want a more customizable and long living environment for development. This process is also recommended if you do not want to install or use Docker.

Installing with Vagrant provides the benefit of needing to install only two system dependencies: Virtualbox and Vagrant. Once Vagrant is set up and you have a copy of the Wallaroo codebase, you will only need to run a `vagrant up` command from the `vagrant` directory and you will have Wallaroo and all of its support tools available within the Wallaroo Vagrant Box.

## Wallaroo Up

We recommend this process if you would prefer to use your development environment and do not mind the additional system requirements necessary for Wallaroo to be installed and running on your machine. The Wallaroo Up script automatically takes care of installing everything for setting up a Wallaroo development environment.

This process requires installing several system libraries which may conflict with requirements of other tools in your development environment. We recommend reviewing the process before proceeding.

## Installing from Source

We recommend this process if you would prefer to use your development environment and do not mind the additional set up necessary for Wallaroo to be running on your machine.

This process requires installing several system libraries which may conflict with requirements of other tools in your development environment. We recommend reviewing the process before proceeding.
