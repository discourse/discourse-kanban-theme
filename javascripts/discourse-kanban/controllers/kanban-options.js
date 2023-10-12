import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { equal } from "@ember/object/computed";

export default Controller.extend(ModalFunctionality, {
  kanbanHelper: service(),
  modes: [{ id: "tags" }, { id: "categories" }, { id: "assigned" }],
  tags: [],
  usernames: [],
  categories: [],
  mode: "tags",

  isTags: equal("mode", "tags"),
  isCategories: equal("mode", "categories"),
  isAssigned: equal("mode", "assigned"),

  actions: {
    apply() {
      let href = this.kanbanHelper.hrefForCategory(
        this.kanbanHelper.discoveryCategory
      );
      href += "?board=";
      if (this.isTags) {
        href += "tags";
        if (this.tags.length > 0) {
          href += `:${this.tags.join(",")}`;
        }
      } else if (this.isCategories) {
        href += "categories";
        if (this.categories.length > 0) {
          href += `:${this.categories.join(",")}`;
        }
      } else if (this.isAssigned) {
        href += "assigned";
        if (this.usernames.length > 0) {
          href += `:${this.usernames}`;
        }
      }

      this.send("closeModal");
      DiscourseURL.routeTo(href, { replaceURL: true });
    },
  },
});
