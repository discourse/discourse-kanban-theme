import Service, { inject as service } from "@ember/service";
import Category from "discourse/models/category";
import { get } from "@ember/object";
import buildTagLists from "../lib/kanban-list-builders/tags";
import buildCategoryLists from "../lib/kanban-list-builders/categories";
import buildAssignedLists from "../lib/kanban-list-builders/assigned";

export default class extends Service {
  @service router;

  getBoardUrl({ category, tag, descriptor = "default" }) {
    const categorySlug = category ? Category.slugFor(category) : null;
    let url;
    if (category && tag) {
      url = `/tags/c/${categorySlug}/${tag.id}?board=${descriptor}`;
    } else if (tag) {
      url = `/tags/${tag.id}?board=${descriptor}`;
    } else if (category) {
      url = `/c/${categorySlug}/l/latest?board=${descriptor}`;
    } else {
      url = `/latest?board=${descriptor}`;
    }
    return url;
  }

  discoveryRouteAttribute(path) {
    const { name, attributes } = this.router.currentRoute;
    if (
      (name.startsWith("discovery.latest") ||
        name.startsWith("tags.show") ||
        name === "tag.show") &&
      attributes
    ) {
      return get(attributes, path);
    }
  }

  get discoveryParams() {
    return (
      this.discoveryRouteAttribute("params") ||
      this.discoveryRouteAttribute("modelParams") ||
      this.discoveryRouteAttribute("list.listParams") // tag.show
    );
  }

  get discoveryTopTags() {
    return this.discoveryRouteAttribute("topic_list.top_tags");
  }

  get discoveryCategory() {
    return this.discoveryRouteAttribute("category");
  }

  get discoveryTag() {
    return this.discoveryRouteAttribute("tag");
  }

  get active() {
    return !!this.currentDescriptor;
  }

  get currentDescriptor() {
    return this.discoveryParams && get(this.discoveryParams, "board");
  }

  get listDefinitions() {
    const definition = this.findDefinition();
    return definition?.lists;
  }

  get definitionBuilders() {
    return {
      tags: (param) => buildTagLists({ kanbanHelper: this, param }),
      categories: (param) => buildCategoryLists({ kanbanHelper: this, param }),
      assigned: (param) => buildAssignedLists({ kanbanHelper: this, param }),
    };
  }

  get resolvedDescriptorParts() {
    let descriptor = this.currentDescriptor;

    if (typeof descriptor !== "string") {
      return;
    }

    const setDefaults = settings.default_modes
      .split("|")
      .map((m) => m.split(":"));

    const lookup = this.get("discoveryCategory.slug") || "@";
    const defaultMode = setDefaults.find((m) => m[0] === lookup);
    if (defaultMode && descriptor === "default") {
      defaultMode.shift();
      descriptor = defaultMode.join(":");
    }

    if (descriptor === "default") {
      if (!this.discoveryCategory) {
        descriptor = "categories";
      } else if (
        this.discoveryCategory.subcategories &&
        this.discoveryCategory.subcategories.length > 0
      ) {
        descriptor = "categories";
      } else {
        descriptor = "tags";
      }
    }

    const parts = descriptor.split(":");
    return parts;
  }

  get mode() {
    return this.resolvedDescriptorParts[0];
  }

  findDefinition() {
    const [type, param] = this.resolvedDescriptorParts;

    if (this.definitionBuilders[type]) {
      return this.definitionBuilders[type](param);
    }
  }
}