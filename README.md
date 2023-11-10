# terraform-oci-free-forever
A terraform module that can be used to deploy the following stack;
  - 2x VM.Standard.E2.1.Micro instances (1 OCPU, 1 GB RAM, x86_64);
  - 1x VM.Standard.A1.Flex instance (4 OCPU, 24 GB RAM, aarch64);
  - An additional 59 GB volume that is attached to the VM.Standard.A1.Flex instance
  - A volume backup policy taking one automatic snapshot per week.
