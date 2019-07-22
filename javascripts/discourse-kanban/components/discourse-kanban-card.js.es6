import computed from "ember-addons/ember-computed-decorators";
import renderTag from "discourse/lib/render-tag";
import DiscourseURL from "discourse/lib/url";

export default Ember.Component.extend({
    classNameBindings: [':topic-card', 'dragging', 'topic.unseen:topic-unseen'],
    attributeBindings: ['draggable'],
    draggable: true,

    dragStart(event) {
        this.set("dragging", true);
        this.setDragData({ topic: this.topic });
        event.dataTransfer.setData('topic', this.topic);
    },

    dragEnd(event) {
        this.set("dragging", false);
    },

    click(event) {
        DiscourseURL.routeTo(this.topic.lastUnreadUrl);
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