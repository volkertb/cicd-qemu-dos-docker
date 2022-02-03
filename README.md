# cicd-qemu-dos-docker

## What is this?

A Docker image for CI/CD pipelines that require operations to be performed in a DOS environment. This is for instance
useful for retro DOS projects with build artifacts that are compiled and/or assembled DOS executables that need to be
tested.

## How to use

CI/CD-specific stuff depends on which CI/CD system is being used. Currently, this project contains a GitHub Actions
workflow that should automatically build the Docker image and publish it to GitHub Packages (the GitHub-flavored
container repository). It should then be possible to use it in the GitHub Actions workflows of any project on GitHub
that might need it.

To use this locally, create a directory somewhere and create a CICD.BAT file, as well as any other files that you need
for your specific CI/CD job.

To use this locally, first build the image:

```shell
# You may have to prefix the following command with `sudo `, depending on your environment.
docker build -t volkertb/cicd-qemu-dos-docker:0.1 .
```

create a directory somewhere and create a `CICD.BAT` file in it, as well as any other files that you need
for your specific CI/CD job. The Docker instance will try to run that file in an emulated DOS environment, if you mount
the directory correctly while starting up the Docker instance. Assuming that you built a local Docker image with the
aforementeioned `docker build` command, and the directory you created for this has the
local path `/path/to/cicd_dir`, the command to run the Docker instance should be the following:

```shell
# You may have to prefix the following command with `sudo `, depending on your environment.
docker run --mount type=bind,src=/path/to/cicd_dir,dst=/mnt/drive_d -it volkertb/qemu-alpine-docker:0.1
```

If whatever commands you added to the `CICD.BAT` in the `/path/to/cicd_dir` write any files in the current directory,
they should appear in that directory after the Docker instance completes its run and shuts down.
