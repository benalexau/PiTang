# PiTang

*PiTang* allows you to easily set up a [Tang](https://github.com/latchset/tang)
server on a Raspberry Pi 4, with the Tang key files themselves maintained on an
encrypted file system.

## Features

* Ten minutes from download to a production-quality Tang deployment
* Tang keys are encrypted so that they cannot be used without a password
* Optimised for widely available and low cost Raspberry Pi 4 hosts
* Easy backup, restore and key rotation approaches for peace of mind
* File systems operate in read-only mode (eliminating SD card wear failure)
* Prometheus enabled for easy HTTP-based monitoring
* Easy, optional upgrades (minimal packages, rolling Arch Linux distribution) 

## Motivation

Network Bound Disk Encryption reduces the barriers to deploying disk encryption
across server fleets. Servers with encrypted disks access a local network Tang
service that can recover their encryption key. This allows those servers to
automatically unlock and boot without operator invention.

A simple and automatic disk encryption model encourages the routine encryption
of server drives. This reduces the time, risk and complexity of both common
events (drive failure, retirement, replacement etc) and less common ones (drive
misplaced, lost, stolen etc).

With the key management effectively moved to the Tang server, one challenge is
how to reliably and securely deploy such servers on a network. PiTang provides a
simple way to deploy dedicated Tang servers on Raspberry Pi 4 hosts. PiTang has
a special focus on encrypting Tang's encryption keys so that they cannot be used
until the root user unlocks them after each boot.

## Scope and Limitations

PiTang aims to mitigate relatively unsophisticated actors physically acquiring
encrypted server disks and a Tang server that holds the associated encryption
keys. The disconnection of power causes the encrypted volumes to be closed, and
they cannot be re-opened until the encryption password is provided to the PiTang
server.

A sophisticated, targeted attacker could use various approaches to defeat these
protections. A partial list includes:

* Accessing Tang from an unauthorised client (eg on a remote network)
* Ensuring the Raspberry Pi maintains power during any physical recovery
* Installing malware (eg key loggers) to collect the encryption password
* Remotely accessing the data once the encrypted volumes have been unlocked
* Exploiting unknown or unpatched vulnerabilities or misconfigurations

If your threat model includes highly advanced or targeted attacks, it is
unlikely that convenient approaches like Network Bound Disk Encryption are
appropriate. Other alternatives (eg air gapped machines, dedicated hardware
or cloud security modules, encrypted USB keys with hardware pin pads to store
disk encryption keys etc) are probably worth considering.

## Getting Started

You will need the *PiTang* Raspberry Pi image. You can build it yourself using
the instructions at the bottom of this file, or you can download the latest
image created by [GitHub Actions](https://github.com/benalexau/PiTang/actions)
(these are built once per month and on pushes to this repository). To download
the GitHub Actions build, select the most recent successful build (identified by
a green tick) and then download the "PiTang Raspberry Pi 4" from "Artifacts".

Write the image file to an SD card using a command such as:

```
sudo dd if=pitang.img of=/dev/sdd bs=4M && sync
```

After writing the image file to an SD card and putting it in a Raspberry Pi,
boot the Raspberry Pi. It will obtain a DHCP address and you can then SSH into
it as root (the default password is also "root"). Then:

1. Append your SSH key to `/root/.ssh/authorized_keys` (or use `ssh-copy-id`)
2. Logout and login again over SSH to verify the certificate was used
3. Edit `/etc/ssh/sshd_config`, changing `PermitRootPassword yes` to
   `PermitRootPassword without-password` (`mg`, `vi` and `nano` are installed)
4. Disable the root password using `passwd --lock root`
5. Run `pitang-setup` and select a disk encryption password
6. Run `ro` to make the system read only (this survives reboots)
7. Copy `/root/tang.img` to a suitable remote location for backup
8. You're finished, so it's time to `reboot` to verify everything works

## Unlocking

The Tang keys are kept on an encrypted file system. This file system must be
opened using the password you nominated in the `pitang-setup` step, mounted to
the Tang `/var/db/tang` path, and finally Tang itself started. We call this
"unlocking" and provide a convenient script that handles it all. To unlock a
freshly booted PiTang server:

1. SSH in as root
2. Run `pitang-unlock` and provide the disk encryption password
3. The Tang public keys are then displayed to confirm the server is working

If desired you can `pitang-lock` to stop Tang and close the encrypted file
system. This is not strictly necessary; a `reboot` has the same consequence.

The PiTang scripts use systemd to start and stop Tang at the appropriate times.
Please do not use systemd to manually control Tang given the encrypted file
systems may not be currently initialised, unlocked or mounted.

## Backup and Recovery

It is essential that you backup Tang's server key files. These key files are
assigned when you run `pitang-setup`. They are also modified if you perform a
manual key rotation (covered below). The mere processing of client requests does
not modify any Tang state whatsoever, so there is no need to take regular or
recurring backups of a PiTang deployment. Indeed the lack of mutable state is
why the setup instructions above activated a read-only configuration after the
initial setup was complete.

There are many ways to backup Tang's server key files. But given we already have
an encrypted file system container that is usually immutable (`/root/tang.img`),
it's simplest to just copy that encrypted file to another location (eg a USB
drive, cloud storage, private source code repository etc). The PiTang scripts
routinely display a `sha256sum` so that you can easily verify the backups
without needing to actually unlock them.

To recover a PiTang server, download a fresh PiTang image and follow the setup
instructions up to the point you'd normally run `pitang-setup`. Instead of
running `pitang-setup`, simply restore the `/root/tang.img` file from your
backup. Complete the remainder of the instructions and you should be finished. 

An alternative to backing up the `tang.img` is to `pitang-unlock` then backup
the `/var/db/tang` files. However as these files are not encrypted, special care
must be taken to secure them (eg store them in a password manager). To recover
from a backup of this type, install a fresh PiTang server and then follow the
key rotation instructions (below) to replace files in `/var/db/tang`. This
backup approach is not recommended given the higher level of risk and restore
complexity.

## High Availability

If you require a highly available Tang service, the Tang authors recommend that
you deploy multiple Tang servers (each with their own key) and configure clients
to use any of those servers.

Alternately you could deploy multiple PiTang servers with the same `tang.img`.
This would allow any of those servers to process requests. You can then place a
reverse proxy server in front (given Tang uses HTTP) or deploy something like
`keepalived` to provide a floating, virtual IP address.

## Key Rotation

The Tang authors recommend to rotate keys periodically. To do this:

1. Run `pitang-lock` to close the read-only, encrypted file system
2. Run `rw` to obtain a read-write file system
3. Run `pitang-unlock` to mount the encrypted (and now writable) file system
4. Perform key rotation in `/var/db/tang` as per Tang documentation
5. Run `pitang-lock` to close the encrypted file system
6. Run `ro` to make the file system read only again
7. Backup `/root/tang.img`
8. Optionally `reboot` to verify correct startup behaviour
9. Run `pitang-unlock` to resume usual (read only) operation

## Monitoring

You may monitor the overall system by HTTP requests to `http://host:9100/metrics`.
This is a standard Prometheus Node Exporter endpoint.

You may also monitor Tang itself by HTTP requests to `http://host/adv`. This
returns the public keys on the Tang server. It will only be available after
unlocking.

## Software Updates

The PiTang image uses Arch Linux, which is a popular rolling distribution. While
the author has operated Arch Linux for over 15 years and updates very rarely
fail, the reality is that any upgrade brings with it some risk of failure and
any potential benefits must be considered against that risk.

If later software is required, the recommended upgrade path is to download and
deploy the latest version of PiTang, using the `tang.img` backup and restore
approach so the Tang key files can be transferred to the latest version. Deploy
the new version on a separate SD card from your existing deployment, therefore
ensuring there is a simple rollback plan for your existing Tang service.

If you wish to attempt a rolling software update without installing a new
version of PiTang :

1. Consider copying the production SD card to a file on another machine (eg
   `sudo dd if=/dev/sdd of=~/pitang-prod.img bs=4M && sync`)
2. SSH into the PiTang server as root
3. Run `pitang-lock` to close the Tang encrypted file system container
4. Ensure that you have an up-to-date, remote backup of `tang.img`
5. Run `rw` to obtain a read-write file system
6. Run `pacman -Syu` to perform the actual Arch Linux upgrade
7. Run `ro` to return to a read-only file system
8. Run `reboot` to test the upgrade was successful

If the above fails, you can either restore your PiTang environment using the
SD card backup image, or you can download a new PiTang version and restore the
`tang.img` as per the usual backup and restore procedure.

## Building

[packer-builder-arm](https://github.com/mkaczanowski/packer-builder-arm) is used
to build a standard image file that can be written to SD cards.

To build your own image, run:

```
PACKER_LOG=1 sudo packer build pitang.json
```

## Contributing

*PiTang* strongly prioritises operational reliability through simplicity,
security and zero provisioning. Enhancements that reflect these priorities are
most welcome.

## Support

Please open a GitHub ticket if you have any questions.
