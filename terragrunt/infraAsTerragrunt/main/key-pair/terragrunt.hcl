terraform {
  source = "../../modules/key-pair"
}

include "root" {
  path = find_in_parent_folders()
}


inputs = {
    key_name = "my_key"
}