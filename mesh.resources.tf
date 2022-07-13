module "mesh" {
  count     = var.mesh != null ? 1 : 0
  source    = "app.terraform.io/ninjadev/mesh/aws"
  version   = "1.0.0"
  env       = terraform.workspace
  vpc_id    = var.vpc_id
  mesh      = var.mesh.name
  namespace = var.mesh.namespace
  services = [
    for service in var.ecs.services : {
      name    = service.name
      family  = service.family
      port    = service.port
      backend = service.backend
    }
  ]
  routers = var.mesh.routers
}
