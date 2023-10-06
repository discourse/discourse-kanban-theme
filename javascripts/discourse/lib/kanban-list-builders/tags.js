export default function buildTagLists({ kanbanHelper, param }) {
  const tags = [];
  if (param) {
    tags.push(...param.split(","));
  } else if (kanbanHelper.discoveryTopTags) {
    tags.push(...kanbanHelper.discoveryTopTags);
  }

  const lists = [];

  lists.push(
    ...tags.map((tag) => {
      if (tag === "@untagged") {
        return {
          title: "Untagged",
          params: {
            no_tags: true,
          },
        };
      } else {
        return {
          title: `#${tag}`,
          params: {
            tags: [tag],
          },
        };
      }
    })
  );

  return { lists };
}
