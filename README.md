# rpi-forklift-demo

A simple demo of using Forklift to set up and manage a Raspberry Pi OS-based system

## Introduction

This repository provides SD card images for a
simple [Raspberry Pi OS bookworm](https://www.raspberrypi.com/software/operating-systems/)-based
demo for integrating [Forklift](https://github.com/PlanktoScope/forklift) to manage OS configuration
files and Docker Compose apps.

## Usage

(the guide below refers to terms specific to Forklift; if you get confused, you can jump down to the
[Explanation](#explanation) section to read a long summary of what those terms mean)

### Prerequisites

You will need to have a Raspberry Pi 3B/3B+/4/5 board which is attached to a keyboard and display,
and which you can connect to the internet via either of two ways:

1. An ethernet cable
2. A phone connected to the Raspberry Pi in "USB tethering" mode.

### Set up your Raspberry Pi

You will need to download the latest version of the SD card image. To do so, go to
<https://github.com/ethanjli/rpi-forklift-demo/actions/workflows/build-os-lite.yml> (for a
CLI-only OS image) or
<https://github.com/ethanjli/rpi-forklift-demo/actions/workflows/build-os-desktop.yml> (for an
OS image with the Raspberry Pi OS desktop), click on the most recent workflow run which was
triggered by the `main` branch (not any feature branches! the OS images built from feature branches
are works-in-progress which are probably broken in various ways) and which completed successfully,
and download the `rpi-forklift-demo-lite-latest.zip` or
`rpi-forklift-demo-desktop-latest.zip` artifact from it; the download should be ~1-2 GB. The
ZIP archive contains the SD card image as a `.img.gz` file; you should extract the `.img.gz` file
from the `.zip` archive, flash an SD card with it, insert it into your Raspberry Pi, and boot your
Raspberry Pi.

Afterwards, if you log in with username `pi` and password `copepode` and run
`curl -L localhost:3000/whoami` in the terminal, then you should see some output which looks like:

```
Hostname: ...
IP: 127.0.0.1
IP: ::1
IP: ...
RemoteAddr: ...
GET / HTTP/1.1
Host: localhost:3000
User-Agent: curl/7.74.0
...
```

This webpage is provided by a Docker container for the image `traefik/whoami` (which you can see
listed if you run the command `docker ps -a`), reverse-proxied
onto `localhost:3000/whoami` by a Docker container for the image `lucaslorentz/caddy-docker-proxy`.
You can see these containers, and their port mappings, by running `docker ps -a`. Note that nothing
is actually listening on `localhost:80`, which you can confirm by running `curl localhost`.

### Use a pallet

This VM image comes the Forklift pallet at the latest commit from the `main` branch of
[github.com/ethanjli/pallet-example-minimal](https://github.com/ethanjli/pallet-example-minimal),
as a minimal demo. This guide will show you how to switch to a different pallet, at release v0.1.0
of [github.com/ethanjli/rpi-forklift-demo](https://github.com/ethanjli/rpi-forklift-demo)
(i.e. the repository which contains the `README.md` file you're reading right now)
and apply it to your VM.

To clone and stage the pallet, just run (with your Raspberry Pi connected to the internet, which
you can confirm by running the command `ping -c 3 github.com` to see if you get any responses):

```
forklift pallet switch github.com/ethanjli/rpi-forklift-demo@v0.1.0
```

(Note: if you hate typing, then you can replace `pallet` with `plt` - that's three entire keypresses
saved!!)

This pallet modifies the OS's configuration files, so you should reboot to apply its changes:

```
sudo reboot
```

This pallet uses the same Docker container image `traefik/whoami` as in the previous
github.com/ethanjli/pallet-example-minimal pallet, but this one configures the Docker container to
be accessed directly on port 80 instead; you can confirm this by running `docker ps -a` to see the
port mapping settings (which are now blank, since the container now uses host networking rather
than port mapping), and by running `curl -L localhost` (which will work) and
`curl -L localhost:3000/whoami` (which will fail).

This pallet also adds some OS configuration files to change networking settings - so that now you
can access the web page either:

- at `http://raspberrypi.demo/` from your Raspberry Pi, or
- from any computer connected to your Raspberry Pi by an Ethernet cable or by the Wi-Fi network
  which your Raspberry Pi now creates (with SSID `raspberrypi` and password `copepode`).

### Modify a pallet and use it

You can modify your local copy of the pallet, which is at `~/.local/share/forklift/pallet`, either
using the Forklift CLI or by directly editing YAML files in your local copy of the pallet; after
making changes, you can stage (and apply) the modified pallet. This guide will show you how to use
the Forklift CLI to modify the local pallet.

To add a package deployment for a Forklift package, you will need to specify the version of the
Forklift repository which will be used to provide that package for the pallet. You can add the
latest commit on the `edge` branch (which is the development branch) of the Forklift package
repository `github.com/PlanktoScope/device-pkgs` by running:

```
forklift plt add-repo github.com/PlanktoScope/device-pkgs
```

For this demo, we'll add a deployment for the package
`github.com/PlanktoScope/device-pkgs/core/host/machine-name`; you can view information about it by
running:

```
forklift plt show-pkg github.com/PlanktoScope/device-pkgs/core/host/machine-name
```

You can see that this package has two optional feature flags which can be enabled; for this demo,
we care about `generate-hostname-templated`, which will automatically update `/etc/hostname` from a
template file at `/etc/hostname-template`. Our pallet already includes a package deployment named
`custom-domain` which provides a file at `/etc/hostname-template`; you can view information about it
by running:

```
forklift plt show-depl custom-domain
```

You can run the following command to add a new package deployment, named `my-experiment`, of
the package `github.com/PlanktoScope/device-pkgs/core/host/machine-name`:

```
forklift plt add-depl my-experiment github.com/PlanktoScope/device-pkgs/core/host/machine-name
```

Then you can run the following command to enable the `generate-hostname-templated` feature flag:

```
forklift plt enable-depl-feat my-experiment generate-hostname-templated
```

If you run `forklift plt show-depl my-experiment`, you can see that `generate-hostname-templated`
is listed as an enabled feature.

To apply the changes you just made to the pallet, you should run the following command and then
reboot (e.g. with the `sudo reboot` command):

```
forklift plt stage
```

After rebooting and opening (or logging in to) the terminal, you will see that the Raspberry Pi's
hostname has changed from `raspberrypi` to something like `pi-bitter-floor-43365`; this hostname
is automatically generated based on the Raspberry Pi's serial number, due to a static binary and
some system services provided by `my-experiment` package deployment we had just added:

- `/usr/bin/machine-name`: you can view information about this program by running
  `ls -l /usr/bin/machine-name` and `machine-name help`.

- `generate-machine-name.service`: you can view information about this service by running
  `systemctl cat generate-machine-name.service` and
  `systemctl status generate-machine-name.service`.

- `generate-hostname-templated.service`: you can view information about this service by running
  `systemctl cat generate-hostname-templated.service` and
  `systemctl status generate-hostname-templated.service`.

### Switch to another pallet

You can switch to another pallet from GitHub/GitLab/etc. using the `forklift pallet switch` command;
it will totally replace the contents of `~/.local/share/forklift/pallet` and create a new staged
pallet bundle in the stage store (which is at both `~/.local/share/forklift/stages` and
`/var/lib/forklift/stages`). Each time you run `forklift pallet switch` or `forklift pallet stage`,
`forklift` will create a new staged pallet bundle in the stage store. You can query and modify the
state of your stage store by running `forklift stage show` and by running other subcommands of
`forklift stage`; if you just run `forklift stage`, it will print some information about the
available subcommands.

For this demo, let's switch back to the unmodified pallet:

```
forklift plt switch github.com/ethanjli/rpi-forklift-demo@v0.1.0
sudo reboot
```

After rebooting, you should see that the hostname has changed back to `raspberrypi`. You can also
confirm that the `/usr/bin/machine-name` binary and the `generate-machine-name.service` and
`generate-hostname-templated.service` services no longer exist by re-running their corresponding commands:

```
ls -l /usr/bin/machine-name
machine-name help
systemctl cat generate-machine-name.service
systemctl status generate-machine-name.service
systemctl cat generate-hostname-templated.service
systemctl status generate-hostname-templated.service
```

Now let's switch to the most recent commit on the development branch of a different pallet,
`github.com/PlanktoScope/pallet-standard`:

```
forklift plt switch github.com/PlanktoScope/pallet-standard@edge
sudo reboot
```

After rebooting and entering the terminal, you can see that the hostname has changed to a different
format (something like `pkscope-bitter-floor-43365`, instead of `raspberrypi` or
`pi-bitter-floor-43365`). Additionally, if you run `curl localhost` again, you can see that now a
different webpage is served. You can also run `docker ps -a` to see that the Raspberry Pi is now
running a lot more Docker containers, and that Forklift has deleted the previous pallet's
`hello-world-whoami-1` container based on the `traefik/whoami` image.

### Modify a pallet safely

Earlier in the demo, we added an external package to our pallet. Now we'll do the same thing, but
we'll try to make some changes that would lead to an invalid system if they were applied to the
system. First, let's try to add a deployment of the
`github.com/ethanjli/rpi-forklift-demo/deployments/hello-world` package, and then stage the
modified pallet:

```
forklift plt add-repo github.com/ethanjli/rpi-forklift-demo@v0.1.0
forklift plt add-depl my-conflict github.com/ethanjli/rpi-forklift-demo/deployments/hello-world
forklift plt stage
```

We can see that the `forklift plt stage` command has failed and that Forklift has prevented us from
applying the modified pallet, since it would take our system into an invalid state where the
`my-conflict` package deployment provides a program which wants to listen on port 80, while the
`host/caddy-ingress` package deployment also provides a program which wants to listen on port 80.
Once we resolve the conflict, then we can apply the pallet again:

```
forklift plt rm-depl my-conflict
forklift plt stage
```

Now let's try to remove another package deployment and apply the result:
```
forklift plt rm-depl infra/prometheus
forklift plt stage
```

We can see that the `forklift plt stage` command has failed and that Forklift has prevented us from
applying the modified pallet, since it would take our system into an invalid state where the
`infra/grafana` package deployment requires a network service which no longer exists because it was
provided by the `infra/prometheus` package deployment which we just removed.
Once we resolve the conflict, then we can apply the pallet again:
```
forklift plt add-depl my-fix github.com/PlanktoScope/device-pkgs/core/infra/prometheus
forklift enable-depl-feat my-fix api
```

Now let's switch back to the unmodified pallet:

```
forklift plt switch github.com/PlanktoScope/pallet-standard@edge
```

Once you reboot, you can see that the system still has the same hostname and Docker containers
as before.

# Explanation

## What is Forklift?

Forklift is an experimental prototype tool primarily designed to make it simpler to build OS images
(esp. custom images) of non-atomic Linux distros which need to provide a set of Docker Compose apps
and/or a custom layer of any OS files (where the specific directories to layer should be decided by
the maintainer of the custom OS image, not by Forklift); and to enable users/operators to quickly &
cleanly upgrade/downgrade/reprovision their deployment of those Docker Compose apps and OS files
without having to re-install the custom OS image. Currently Forklift is designed/developed/tested
mainly for the Raspberry Pi OS-based
[operating system of a specific hardware project](https://docs-edge.planktoscope.community/reference/software/architecture/os/).

In Forklift, OS files and Docker Compose apps are
modularized into *Forklift packages*; a package is just a directory which contains a special
`forklift-package.yml` file and which is somewhere inside a *Forklift repository*, which is just a
Git repository with a special `forklift-repository.yml` file at the root of the repository. A
package can declare some files within the package's directory which should be made available at some
declared paths in a special *export directory* (more on this later). Forklift packages and
repositories are roughly analogous to [Go packages and modules](https://go.dev/ref/mod),
respectively - except that Forklift packages/repositories cannot "import" or "include" other
Forklift packages/repositories, and the path of the Forklift repository must be exactly the path of
its Git repository (e.g. `github.com/ethanjli/example-exports` is valid, but
`github.com/ethanjli/example-exports/v2` and `github.com/ethanjli/forklift-demos/example-exports`
are not valid repository paths); these differences from the design of Go Modules keep Forklift's
design simpler for Forklift's specific use-case.

## What is a "pallet"?

Forklift packages cannot be deployed/installed on their own. Instead, we create a *Forklift pallet*
to declare the complete configuration of all Forklift packages which should be deployed on a
computer. A pallet is just a Git repository with a special `forklift-pallet.yml` file at the root
of the repository, and some other special files in a special directory structure. We can then use
Forklift or Git to clone the pallet to our computer, and then we can use Forklift to *stage* the
pallet to be applied to our computer. When Forklift stages a pallet, it copies various files into
a new directory called a *staged pallet bundle* (look,, naming is hard; I welcome suggestions for
better names) in a special directory called the *stage store* (again, please help me come up with a
better name). Inside the staged pallet bundle is a subdirectory called `exports` which contains all
the files declared for export by the pallet's deployed packages.

We can add a systemd service which runs during early boot (e.g. before `sysinit.target` or
`local-fs.target`) and queries Forklift for the path of the staged pallet bundle which should be
applied to the computer, and then bind-mounts or overlay-mounts or symlinks-to a subdirectory in
that bundle's `exports` subdirectory for an arbitrary path on the filesystem, e.g. `/usr` or `/etc`
or whatever you're interested in. Then we can add a systemd service which refreshes systemd's view
of systemd units which need to be started. The demo in this repository sets up filesystem overlays
for `/etc` and `/usr` with
`/var/lib/forklift/stages/{id of the staged pallet bundle to apply}/exports/overlays/etc` and
`/var/lib/forklift/stages/{id of the staged pallet bundle to apply}/exports/overlays/usr`
as intermediate layers, respectively, and refreshes systemd afterwards.

## What does `forklift pallet switch` do?

Behind-the-scenes, running `forklift pallet switch {path of pallet}@{version query}` will:

1. Clone the pallet as a Git repository to a local copy at `~/.local/share/forklift/pallet`, and
   check out the latest commit of the `main` branch; if anything was previously at
   `~/.local/share/forklift/pallet`, it's deleted beforehand.
   This step can also be run on its own with
   `forklift pallet clone --force {path of pallet}@{version query}`.
2. Download any external Forklift repositories required by the pallet into
   `~/.cache/forklift/repositories`.
   This step can also be run on its own with `forklift pallet cache-repo`.
3. Run some checks to ensure that the pallet is valid, e.g. that deployed packages don't conflict
   with each other.
   This step can also be run on its own with `forklift pallet check`.
4. Stage the pallet to be used on the next reboot, by creating a new staged pallet bundle in
   `/home/pi/.local/share/forklift/stages` (which, in this OS image, is attached to
   `/var/lib/forklift/stages` via a bind-mount created by the
   `bind-.local-share-forklift-stages@-home-pi.service` system service).
   This step can also be run on its own with `forklift pallet stage`.
