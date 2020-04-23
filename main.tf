module "myfunction" {
    source              = "./functionapp"
    name                = "myRayphpFunction"
    location            = "australiaeast"
    plan_type           = "consumption"
    func_version        = "~3"
    function_worker_runtime = "php"
    functionapp_path    = "./azure-functions-php-master.zip"
}
