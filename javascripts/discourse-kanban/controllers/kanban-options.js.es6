import DiscourseURL from "discourse/lib/url";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Ember.Controller.extend(ModalFunctionality, {
    kanbanHelper: Ember.inject.service(),
    modes: ["tags", "categories", "assigned"],
    tags: [],
    usernames: [],
    categories: [],
    mode: "tags",

    isTags: Ember.computed.equal("mode", "tags"),
    isCategories: Ember.computed.equal("mode", "categories"),
    isAssigned: Ember.computed.equal("mode", "assigned"),

    actions: {
      apply() {
        var href = this.kanbanHelper.hrefForCategory(
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
      }
    }
  })