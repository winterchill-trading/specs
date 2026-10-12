# Using OCaml to drive a Raspberry Pi robot car

- Source: <https://blog.janestreet.com/using-ocaml-to-drive-a-raspberry-pi-robot-car/>
- Published: 2019-08-19
- Kind: blog post

## Summary

- Motivation: Raspberry Pi is a common teaching platform, mostly for Python; the authors
  tried it for teaching OCaml and Async by driving small robot cars. By 2019 opam on Raspbian
  installed OCaml, Base and Async without trouble.
- Two kits on a Raspberry Pi 3B+: a three-wheeled car with servo steering and a four-wheeled
  car that turns in place by running the sides at different speeds; both have a camera and
  an ultrasonic distance sensor, and come with Python samples.
- The three-wheeled car is driven over I2C/SMBus; the authors wrote small OCaml SMBus
  bindings and a robot API for LEDs, buzzer, motor PWM, sonar distance and three servos.
- A `Sonic_scan` module sweeps the sonar across a list of angles on a periodic Async timer
  (`Clock_ns.every'`) and exposes the latest distances, hiding the concurrency from the
  driving loop.
- Driving logic: stop under 20 cm, go straight over 60 cm, otherwise steer away from the
  nearer side; enough to follow a corridor, with a PID controller suggested as the upgrade.
- The four-wheeled car uses GPIO directly by memory-mapping `/dev/gpiomem`; the OCaml GPIO
  API uses phantom types so input pins cannot be written and output pins cannot be read.
- Its sonar measures echo time assuming 340 m/s; a simple loop goes forward until an
  obstacle is within 60 cm, then turns.
- Follow-ups: YOLOv3 vision (the Pi is too slow; a GPU board would help), lidar, and SLAM.

## Relevance to us

- **OCaml practice:** phantom type parameters make illegal uses of a handle fail to compile
  at no runtime cost. **Action:** none; our order and connection handles in the clients have
  no read-versus-write split that would benefit today.
- Otherwise a hobby and teaching project; nothing maps onto our repos.

Tags: `hardware`, `async`, `education`
