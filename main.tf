module "myfunction" {
    source              = "./functionapp"
    name                = "phpfunction5"
    location            = "australiaeast"
    plan_type           = "consumption"
    func_version        = "~1"
    functionapp_path    = "./functionapp.zip"
}
