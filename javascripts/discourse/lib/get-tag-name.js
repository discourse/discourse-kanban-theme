// TODO: Once 2026.2.0 is released, add a .discourse-compatibility entry and
// remove this helper. After that, tag.name can be used directly.
export default function getTagName(tag) {
  return typeof tag === "string" ? tag : tag.name;
}
