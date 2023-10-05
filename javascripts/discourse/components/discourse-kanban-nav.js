import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import DiscourseURL from "discourse/lib/url";

export default Component.extend({
  tagName: "a",
  attributeBindings: "href",
  classNameBindings: "active",
  kanbanHelper: service(),

  @discourseComputed("category")
  href(category) {
    return this.kanbanHelper.hrefForCategory(category);
  },

  @discourseComputed("filterMode", "kanbanHelper.active")
  active(filterMode, active) {
    return filterMode.split("/").pop() === "latest" && active;
  },

  click(event) {
    event.preventDefault();
    DiscourseURL.routeTo(`${this.href}?board=default`);
  },
});
