terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "gh-actions" {
  # az group list --output table
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
  name     = "gh-actions"
  location = "westus2"  # Changed from eastus
}


resource "azurerm_service_plan" "web-api" {
  # az appservice plan list --output table
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan
  name                = "web-api"
  resource_group_name = azurerm_resource_group.gh-actions.name
  location            = azurerm_resource_group.gh-actions.location

  # legacy app_service docs say must set `reserved` to true (on the plan) if using linux_fx_version
  os_type  = "Linux"
  sku_name = "B1" # B1 - Basic ($13/month), more quota available than F1
}

resource "azurerm_linux_web_app" "web-api" {
  # az webapp list --output table
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app
  name                = "tjm-gh-actions-web-api" # => https://tjm-gh-actions-web-api.azurewebsites.net # *** MAKE SURE TO SET NEW NAME (one universal namespace for everyone) ***
  resource_group_name = azurerm_resource_group.gh-actions.name
  location            = azurerm_resource_group.gh-actions.location

  service_plan_id = azurerm_service_plan.web-api.id

  site_config {
    # site_config options: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app#always_on
    always_on = true # can be true for B1 (basic tier)

    # legacy app_service used linux_fx_version: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service#linux_fx_version
    #   i.e. linux_fx_version = "DOCKER|terryjmitchell/actions-web:latest"
    #   use application_stack instead:
    application_stack {
      docker_image_name   = "terryjmitchell/actions-web:latest"
      docker_registry_url = "https://index.docker.io" # azurerm UI marks this required (when not set), docs for linux_web_app terraform module say its optional ... w00t, setting this here makes the UI pick "Docker Hub" in azurerm AND now container is running!
    }

  }

  # test with:
  # curl -L http://tjm-gh-actions-web-api.azurewebsites.net
  # curl -L http://tjm-gh-actions-web-api.azurewebsites.net/weatherForecast

}
