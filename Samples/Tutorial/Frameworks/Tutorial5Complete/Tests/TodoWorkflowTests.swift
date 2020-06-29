/*
 * Copyright 2020 Square Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import BackStackContainer
import Workflow
import WorkflowTesting
import XCTest
@testable import Tutorial5

class TodoWorkflowTests: XCTestCase {
    func testSelectingTodo() {
        let todos: [TodoModel] = [TodoModel(title: "Title", note: "Note")]

        TodoWorkflow(name: "MyName")
            // Start from the list step to validate selecting a todo:
            .renderTester(initialState: TodoWorkflow.State(
                todos: todos,
                step: .list
            ))
            // We only expect the TodoListWorkflow
            .expectWorkflow(
                type: TodoListWorkflow.self,
                producingRendering: BackStackScreen.Item(
                    screen: TodoListScreen(
                        todoTitles: ["Title"],
                        onTodoSelected: { _ in }
                    ).asAnyScreen()),
                // Simulate selecting the first todo:
                producingOutput: TodoListWorkflow.Output.selectTodo(index: 0)
            )
            .render { items in
                // Just validate that there is one item in the backstack.
                // Additional validation could be done on the screens returned if so desired.
                XCTAssertEqual(1, items.count)
            }
            // Validate that the state was updated after the last render pass with the output from the TodoEditWorkflow.
            .assert(
                state: TodoWorkflow.State(
                    todos: [TodoModel(title: "Title", note: "Note")],
                    step: .edit(index: 0)
                )
            )
    }

    func testSavingTodo() {
        let todos: [TodoModel] = [TodoModel(title: "Title", note: "Note")]

        TodoWorkflow(name: "MyName")
            // Start from the edit step so we can simulate saving:
            .renderTester(initialState: TodoWorkflow.State(
                todos: todos,
                step: .edit(index: 0)
            ))
            // We always expect the TodoListWorkflow
            .expectWorkflow(
                type: TodoListWorkflow.self,
                producingRendering: BackStackScreen.Item(
                    screen: TodoListScreen(
                        todoTitles: ["Title"],
                        onTodoSelected: { _ in }
                    ).asAnyScreen()
                )
            )
            // Expect the TodoEditWorkflow. Additionally, simulate it emitting an output of ".save" to update the state.
            .expectWorkflow(
                type: TodoEditWorkflow.self,
                producingRendering: BackStackScreen.Item(
                    screen: TodoEditScreen(
                        title: "Title",
                        note: "Note",
                        onTitleChanged: { _ in },
                        onNoteChanged: { _ in }
                    ).asAnyScreen()
                ),
                producingOutput: TodoEditWorkflow.Output.save(TodoModel(
                    title: "Updated Title",
                    note: "Updated Note"
                ))
            )
            .render { items in
                // Just validate that there are two items in the backstack.
                // Additional validation could be done on the screens returned if so desired.
                XCTAssertEqual(2, items.count)
            }
            // Validate that the state was updated after the last render pass with the output from the TodoEditWorkflow.
            .assert(
                state: TodoWorkflow.State(
                    todos: [TodoModel(title: "Updated Title", note: "Updated Note")],
                    step: .list
                )
            )
    }
}
