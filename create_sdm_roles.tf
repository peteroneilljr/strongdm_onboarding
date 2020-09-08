
resource "sdm_role" "admins" {
  count = length(var.admin_users) > 0 ? 1:0
  name = "${var.prefix}-admin-role"
}
resource "sdm_role" "read_only" {
  count = length(var.read_only_users) > 0 ? 1:0
  name = "${var.prefix}-read-only-role"
}


resource "sdm_account" "admin_users" {
  count = length(var.admin_users)
  user {
    first_name = split("@", var.admin_users[count.index])[0]
    last_name = split("@", var.admin_users[count.index])[0]
    email = var.admin_users[count.index]
  }
}
resource "sdm_account" "read_only_users" {
  count = length(var.read_only_users)
  user {
    first_name = split("@", var.read_only_users[count.index])[0]
    last_name = split("@", var.read_only_users[count.index])[0]
    email = var.read_only_users[count.index]
  }
}


resource "sdm_account_attachment" "admin_attachment" {
  count = length(var.admin_users)
  account_id = sdm_account.admin_users[count.index].id
  role_id = sdm_role.admins[0].id
}
resource "sdm_account_attachment" "read_only_attachment" {
  count = length(var.read_only_users)
  account_id = sdm_account.read_only_users[count.index].id
  role_id = sdm_role.read_only[0].id
}
