import actionTypes from "actions/actionTypes";
import {
  toggleStory,
  editStory,
  addNewAttributes,
  setLoadingStory,
  setLoadingValue,
  cloneStory,
  storyFailure,
  withoutNewStory,
  createNewStory,
  replaceOrAddNewStory,
} from "models/beta/story";
import * as Note from "models/beta/note";
import * as Task from "models/beta/task";
import * as Label from "models/beta/label";
import { updateIfSameId } from "../services/updateIfSameId";
import { storyScopes } from "./../libs/beta/constants";
import {
  denormalizeStories,
  isEpic,
  isSearch,
  normalizeStories,
  isNew,
  normalizeState,
} from "../models/beta/story";
import { getStoriesByScope } from "../selectors/stories";

const initialState = {
  [storyScopes.ALL]: {},
  [storyScopes.SEARCH]: {},
  [storyScopes.EPIC]: {},
};

const storiesReducer = (state = initialState, action) => {
  const denormalizedStories = denormalizeStories(state[action.from]);

  switch (action.type) {
    case actionTypes.RECEIVE_STORIES: {
      const normalizedData = normalizeStories(action.data);

      if (isEpic(action.from) || isSearch(action.from)) {
        return {
          ...state,
          [action.from]: normalizedData,
        };
      }

      return {
        ...state,
        [action.from]: mergeWithFetchedStories(
          state[action.from],
          normalizedData
        ),
      };
    }
    case actionTypes.RECEIVE_PAST_STORIES:
      const normalizedPastStories = normalizeStories(action.stories);

      return {
        ...state,
        [action.from]: {
          stories: {
            byId: {
              ...state[action.from].stories.byId,
              ...normalizedPastStories.stories.byId,
            },
            allIds: [
              ...state[action.from].stories.allIds,
              ...normalizedPastStories.stories.allIds,
            ],
          },
        },
      };
    case actionTypes.CREATE_STORY:
      const newStory = createNewStory(denormalizedStories, action.attributes);

      return {
        ...state,
        [action.from]: normalizeStories(
          replaceOrAddNewStory(denormalizedStories, newStory)
        ),
      };
    case actionTypes.ADD_STORY:
      return {
        ...state,
        [action.from]: normalizeStories(
          replaceOrAddNewStory(
            denormalizedStories,
            action.story.story,
            action.story.id
          )
        ),
      };
    case actionTypes.CLONE_STORY:
      const clonedStory = cloneStory(action.story);

      return {
        ...state,
        [action.from]: normalizeStories(
          replaceOrAddNewStory(denormalizedStories, clonedStory)
        ),
      };
    case actionTypes.TOGGLE_STORY:
      if (isNew(action)) {
        return {
          ...state,
          [action.from]: normalizeStories(
            withoutNewStory(denormalizedStories, action.id)
          ),
        };
      }

      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(updateIfSameId(action.id, toggleStory))
        ),
      };
    case actionTypes.EDIT_STORY:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.id, (story) => {
              return editStory(story, action.newAttributes);
            })
          )
        ),
      };
    case actionTypes.UPDATE_STORY_SUCCESS:
      return normalizeState(
        allScopes(state, action.story.id, (stories) => {
          return stories.map(
            updateIfSameId(action.story.id, (story) =>
              addNewAttributes(story, {
                ...action.story,
                needsToSave: false,
                loading: false,
              })
            )
          );
        })
      );
    case actionTypes.SORT_STORIES_SUCCESS:
      return normalizeState(
        allScopes(state, null, (stories) => {
          return stories.map((story) => {
            const editingStory = action.stories.find(
              (incomingStory) => story.id === incomingStory.id
            );

            return editingStory
              ? addNewAttributes(story, {
                  ...editingStory,
                  needsToSave: false,
                  loading: false,
                })
              : story;
          });
        })
      );
    case actionTypes.OPTIMISTICALLY_UPDATE:
      return normalizeState(
        allScopes(state, action.story.id, (stories) => {
          return stories.map(
            updateIfSameId(action.story.id, (story) => {
              const newStory = setLoadingValue(action.story, true);
              return addNewAttributes(story, {
                ...newStory,
                needsToSave: false,
              });
            })
          );
        })
      );
    case actionTypes.STORY_FAILURE:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.id, (story) => {
              return storyFailure(story, action.error);
            })
          )
        ),
      };
    case actionTypes.SET_LOADING_STORY:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(updateIfSameId(action.id, setLoadingStory))
        ),
      };
    case actionTypes.ADD_TASK:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.storyId, (story) => {
              return Task.addTask(story, action.task);
            })
          )
        ),
      };
    case actionTypes.REMOVE_TASK:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.storyId, (story) => {
              return Task.deleteTask(action.task, story);
            })
          )
        ),
      };
    case actionTypes.TOGGLE_TASK:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.story.id, (story) => {
              return Task.toggleTask(story, action.task);
            })
          )
        ),
      };
    case actionTypes.DELETE_STORY_SUCCESS:
      return normalizeState(
        allScopes(state, action.id, (stories) => {
          return stories.filter((story) => story.id !== action.id);
        })
      );
    case actionTypes.ADD_NOTE:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.storyId, (story) => {
              return Note.addNote(story, action.note);
            })
          )
        ),
      };
    case actionTypes.HIGHLIGHT_STORY:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map((story) => {
            return story.id === action.storyId
              ? { ...story, highlighted: action.highlighted }
              : story;
          })
        ),
      };
    case actionTypes.DELETE_NOTE:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.storyId, (story) => {
              return Note.deleteNote(story, action.noteId);
            })
          )
        ),
      };
    case actionTypes.ADD_LABEL:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.storyId, (story) => ({
              ...story,
              _editing: {
                ...story._editing,
                _isDirty: true,
                labels: Label.addLabel(story._editing.labels, action.label),
              },
            }))
          )
        ),
      };
    case actionTypes.DELETE_LABEL:
      return {
        ...state,
        [action.from]: normalizeStories(
          denormalizedStories.map(
            updateIfSameId(action.storyId, (story) => ({
              ...story,
              _editing: {
                ...story._editing,
                _isDirty: true,
                labels: Label.removeLabel(
                  story._editing.labels,
                  action.labelName
                ),
              },
            }))
          )
        ),
      };
    case actionTypes.CLOSE_EPIC_COLUMN:
      return {
        ...state,
        [storyScopes.EPIC]: [],
      };
    default:
      return state;
  }
};

const withScope = (reducer) => (state, action) => {
  const from = action.from || storyScopes.ALL;
  action = { ...action, from };

  return reducer(state, action);
};

const allScopes = (stories, storyId, mutation) => ({
  [storyScopes.ALL]: mutation(getStoriesByScope(stories, storyScopes.ALL)),
  [storyScopes.SEARCH]: mutation(
    getStoriesByScope(stories, storyScopes.SEARCH)
  ),
  [storyScopes.EPIC]: mutation(getStoriesByScope(stories, storyScopes.EPIC)),
});

const mergeWithFetchedStories = (currentStories, fetchedStories) => {
  if (Object.values(currentStories).length === 0) {
    const firstStories = { ...fetchedStories };
    fetchedStories.stories.allIds.map((storyId) => {
      const fetchedStory = fetchedStories.stories.byId[storyId];

      firstStories.stories.byId[storyId] = {
        ...fetchedStory,
        serverBased: true,
      };
    });
    return firstStories;
  }

  const mergedStories = { ...currentStories };

  fetchedStories.stories.allIds.map((storyId) => {
    const currentStory = currentStories.stories.byId[storyId];
    const fetchedStory = fetchedStories.stories.byId[storyId];

    if (currentStory && !currentStory.collapsed) {
      mergedStories.stories.byId[storyId] = {
        ...fetchedStory,
        collapsed: false,
        serverBased: true,
        _editing: { ...currentStory._editing },
      };
    } else {
      mergedStories.stories.byId[storyId] = {
        ...fetchedStory,
        serverBased: true,
      };
      if (!mergedStories.stories.allIds.includes(storyId)) {
        mergedStories.stories.allIds.unshift(storyId);
      }
    }
  });

  const updatedMergedStories = filterAndRemoveStories(
    mergedStories,
    fetchedStories
  );

  return updatedMergedStories;
};

const filterAndRemoveStories = (mergedStories, fetchedStories) => {
  const serverBasedIds = Object.values(mergedStories.stories.byId)
    .filter((story) => story.serverBased)
    .map((story) => story.id);

  const storiesToRemove = serverBasedIds.filter(
    (id) => !fetchedStories.stories.allIds.includes(id)
  );

  const updatedStoriesById = { ...mergedStories.stories.byId };

  const updatedStoriesAllIds = mergedStories.stories.allIds.filter(
    (storyId) => !storiesToRemove.includes(storyId)
  );

  storiesToRemove.forEach((storyId) => {
    delete updatedStoriesById[storyId];
  });

  const updatedMergedStories = {
    ...mergedStories,
    stories: {
      byId: updatedStoriesById,
      allIds: updatedStoriesAllIds,
    },
  };

  return updatedMergedStories;
};

export default withScope(storiesReducer);
