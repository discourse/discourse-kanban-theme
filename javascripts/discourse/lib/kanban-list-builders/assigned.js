export default function buildAssignedLists({ param }) {
  const lists = [];

  lists.push({
    title: "Unassigned",
    icon: "user-minus",
    params: {
      assigned: "nobody",
      status: "open",
    },
  });

  if (param) {
    lists.push(
      ...param.split(",").map((u) => {
        return {
          title: u,
          icon: "user-plus",
          params: {
            assigned: u,
            status: "open",
          },
        };
      })
    );
  } else {
    lists.push({
      title: "Assigned",
      icon: "user-plus",
      params: {
        assigned: "*",
        status: "open",
      },
    });
  }
  lists.push({
    title: "Closed",
    icon: "lock",
    params: {
      status: "closed",
    },
  });

  return { lists };
}
