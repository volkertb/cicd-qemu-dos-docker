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

To use this locally, create a directory somewhere and create a CICD_DOS.BAT file, as well as any other files that you
need for your specific CI/CD job.

To use this locally, first build the image:

```shell
# You may have to prefix the following command with `sudo `, depending on your environment.
docker build -t volkertb/cicd-qemu-dos-docker:0.1 .
```

create a directory somewhere and create a `CICD_DOS.BAT` file in it, as well as any other files that you need for your
specific CI/CD job. The Docker instance will try to run that file in an emulated DOS environment, if you mount the
directory correctly while starting up the Docker instance. Assuming that you built a local Docker image with the
aforementioned `docker build` command, and the directory you created for this has the local path `/path/to/cicd_dir`,
the command to run the Docker instance should be the following:

```shell
# You may have to prefix the following command with `sudo `, depending on your environment.
# If the host cannot provide KVM to the Docker container, then leave out the argument `--device=/dev/kvm`.
docker run --device=/dev/kvm --workdir /github/workspace -v "/path/to/cicd_dir":"/github/workspace" volkertb/cicd-qemu-dos-docker:0.1
```

If whatever commands you added to the `CICD_DOS.BAT` in the `/path/to/cicd_dir` write any files in the current
directory, they should appear in that directory after the Docker instance completes its run and shuts down.

Also, the default ENTRYPOINT configures several emulated sound devices, namely AC'97, Adlib/OPL2, SB16, and PC Speaker.
Any sound output that was sent to these emulated devices will be directed to separate WAV files (one for each device),
with names ending with `_out.wav` in `/path/to/cicd_dir` (or whichever directory you configured in its place). This
separation is to make the asserting and verifying of sound output easier, for instance when you're testing support for a
specific sound device.

Granted, the above list of sound devices is somewhat arbitrary at the moment, and mostly suits my specific needs in some
projects I'm working on. But these options are easy to modify, simply by changing the ENTRYPOINT in the Dockerfile, or
by overriding the entrypoint on the command-line when running an instance of the Docker image.

Upon completion of the Docker instance, the QEMU console output can be found in the files `qemu_stdout.log` and
`qemu_stderr.log`, with the latter containing any error output. You can use those to perform additional checks or
assertions on.
