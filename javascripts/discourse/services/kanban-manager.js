import { tracked } from "@glimmer/tracking";
import { get } from "@ember/object";
import Service, { service } from "@ember/service";
import Category from "discourse/models/category";
import buildAssignedLists from "../lib/kanban-list-builders/assigned";
import buildCategoryLists from "../lib/kanban-list-builders/categories";
import buildTagLists from "../lib/kanban-list-builders/tags";

export default class KanbanManager extends Service {
  @service router;
  @service discovery;

  @tracked fullscreen;

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
    return this.discovery.currentTopicList?.get("topic_list.top_tags");
  }

  get discoveryCategory() {
    return this.discovery.category;
  }

  get discoveryTag() {
    return this.discovery.tag;
  }

  get active() {
    return !!this.currentDescriptor;
  }

  get currentDescriptor() {
    return (
      this.discovery.onDiscoveryRoute &&
      this.router.currentRoute?.queryParams?.board
    );
  }

  get listDefinitions() {
    return this.findDefinition()?.lists;
  }

  get definitionBuilders() {
    return {
      tags: (param) => buildTagLists({ kanbanManager: this, param }),
      categories: (param) => buildCategoryLists({ kanbanManager: this, param }),
      assigned: (param) => buildAssignedLists({ kanbanManager: this, param }),
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

    return descriptor.split(":");
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
