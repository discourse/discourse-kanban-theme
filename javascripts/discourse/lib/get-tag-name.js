// TODO(https://github.com/discourse/discourse/pull/36678): The string check can be
// removed using .discourse-compatibility once the PR is merged.
export default function getTagName(tag) {
  return typeof tag === "string" ? tag : tag.name;
}
