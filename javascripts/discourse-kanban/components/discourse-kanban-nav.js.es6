import computed from "ember-addons/ember-computed-decorators";
import DiscourseURL from "discourse/lib/url";

export default Ember.Component.extend({
    tagName: "a",
    attributeBindings: "href",
    classNameBindings: "active",
    kanbanHelper: Ember.inject.service(),

    @computed("category", "kanbanHelper.discoveryTag")
    href(category, tag) {
        if (category) {
            return this.kanbanHelper.hrefForCategory(category);
        } else if (tag) {
            return this.kanbanHelper.hrefForTag(tag);
        } else console.log("error computing href for component");
    },

    @computed("filterMode", "kanbanHelper.active", "kanbanHelper.discoveryTag")
    active(filterMode, active, tag) {
    return filterMode.split("/").pop() == ('latest' && active) || (tag && active);
    },

    click(event) {
        event.preventDefault();
        DiscourseURL.routeTo(`${this.href}?board=default`);
    }
});