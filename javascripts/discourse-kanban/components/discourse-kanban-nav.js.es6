import computed from "ember-addons/ember-computed-decorators";
import DiscourseURL from "discourse/lib/url";

export default Ember.Component.extend({
    tagName: "a",
    attributeBindings: "href",
    classNameBindings: "active",
    kanbanHelper: Ember.inject.service(),

    @computed("category")
    href(category) {
      return this.kanbanHelper.hrefForCategory(category);
    },

    @computed("filterMode", "kanbanHelper.active")
    active(filterMode, active) {
      return filterMode.split("/").pop() === 'latest' && active;
    },

    click(event) {
      event.preventDefault();
      DiscourseURL.routeTo(`${this.href}?board=default`);
    }
  })