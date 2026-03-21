resource "digitalocean_tag" "tag" {
    for_each = toset(var.tags)
    name = each.value
}