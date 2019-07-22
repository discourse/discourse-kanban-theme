import computed from "ember-addons/ember-computed-decorators";
import renderTag from "discourse/lib/render-tag";

export default Ember.Component.extend({
    draggable: "true",

    dragStart(event) {
        this.setDragData({ topic: this.topic });
        this.set("dragging", true);
    },

    dragEnd(event) {
        this.set("dragging", false);
    },

    @computed('tags')
    showTags(tags) {
        return settings.show_tags && tags.length;
    },

    @computed("topic.tags", "definition.params.tags")
    tags(topicTags, definitionTag) {
        return topicTags
        .filter(t => t != definitionTag)
        .map(t => renderTag(t));
    }
});