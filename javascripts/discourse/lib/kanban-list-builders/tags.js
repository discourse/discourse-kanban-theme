export default function buildTagLists({ kanbanManager, param }) {
  const tags = [];
  if (param) {
    tags.push(...param.split(","));
  } else if (kanbanManager.discoveryTopTags) {
    tags.push(...kanbanManager.discoveryTopTags);
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
