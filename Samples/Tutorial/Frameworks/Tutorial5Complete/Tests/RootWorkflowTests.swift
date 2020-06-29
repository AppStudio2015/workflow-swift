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

import Workflow
import WorkflowTesting
import XCTest
// Import `BackStackContainer` as testable so that the items in the `BackStackScreen` can be inspected.
@testable import BackStackContainer
@testable import Tutorial5
// Import `WorkflowUI` as testable so that the wrappedScreen in `AnyScreen` can be accessed.
@testable import WorkflowUI

class RootWorkflowTests: XCTestCase {
    func testWelcomeRendering() {
        RootWorkflow()
            // Start in the `.welcome` state
            .renderTester(initialState: RootWorkflow.State.welcome)
            .render(
                // Expect the state to stay as `.welcome`.
                expectedState: ExpectedState(state: RootWorkflow.State.welcome),
                // No output is expected from the root workflow.
                expectedOutput: nil,
                // There are no workers that should be run.
                expectedWorkers: [],
                // The `WelcomeWorkflow` is expected to be started in this render.
                expectedWorkflows: [
                    ExpectedWorkflow(
                        type: WelcomeWorkflow.self,
                        // Simulate this as the `WelcomeScreen` returned by the `WelcomeWorkflow`. The callback can be stubbed out, as they won't be used.
                        rendering: WelcomeScreen(
                            name: "MyName",
                            onNameChanged: { _ in },
                            onLoginTapped: {}
                        )
                    ),
                ],
                // Now, validate that there is a single item in the BackStackScreen, which is our welcome screen.
                assertions: { rendering in
                    XCTAssertEqual(1, rendering.items.count)
                    guard let welcomeScreen = rendering.items[0].screen.wrappedScreen as? WelcomeScreen else {
                        XCTFail("Expected first screen to be a `WelcomeScreen`")
                        return
                    }
                    XCTAssertEqual("MyName", welcomeScreen.name)
                }
            )
    }

    func testLogin() {
        RootWorkflow()
            // Start in the `.welcome` state
            .renderTester(initialState: RootWorkflow.State.welcome)
            .render(
                // Expect the state to transition to `.todo`
                expectedState: ExpectedState(state: RootWorkflow.State.todo(name: "MyName")),
                // No output is expected from the root workflow.
                expectedOutput: nil,
                // There are no workers that should be run.
                expectedWorkers: [],
                // The `WelcomeWorkflow` is expected to be started in this render.
                expectedWorkflows: [
                    ExpectedWorkflow(
                        type: WelcomeWorkflow.self,
                        // Simulate this as the `WelcomeScreen` returned by the `WelcomeWorkflow`. The callback can be stubbed out, as they won't be used.
                        rendering: WelcomeScreen(
                            name: "MyName",
                            onNameChanged: { _ in },
                            onLoginTapped: {}
                        ),
                        // Simulate the `WelcomeWorkflow` sending an output of `.didLogin` as if the login button was tapped.
                        output: .didLogin(name: "MyName")
                    ),
                ],
                // Now, validate that there is a single item in the BackStackScreen, which is our welcome screen (prior to the output).
                assertions: { rendering in
                    XCTAssertEqual(1, rendering.items.count)
                    guard let welcomeScreen = rendering.items[0].screen.wrappedScreen as? WelcomeScreen else {
                        XCTFail("Expected first screen to be a `WelcomeScreen`")
                        return
                    }
                    XCTAssertEqual("MyName", welcomeScreen.name)
                }
            )
            .assert(state: { state in
                XCTAssertEqual(.todo(name: "MyName"), state)
        })
    }

    func testAppFlow() {
        let workflowHost = WorkflowHost(workflow: RootWorkflow())

        // First rendering is just the welcome screen. Update the name.
        do {
            let backStack = workflowHost.rendering.value
            XCTAssertEqual(1, backStack.items.count)

            guard let welcomeScreen = backStack.items[0].screen.wrappedScreen as? WelcomeScreen else {
                XCTFail("Expected initial screen of `WelcomeScreen`")
                return
            }

            welcomeScreen.onNameChanged("MyName")
        }

        // Log in and go to the welcome list
        do {
            let backStack = workflowHost.rendering.value
            XCTAssertEqual(1, backStack.items.count)

            guard let welcomeScreen = backStack.items[0].screen.wrappedScreen as? WelcomeScreen else {
                XCTFail("Expected initial screen of `WelcomeScreen`")
                return
            }

            welcomeScreen.onLoginTapped()
        }

        // Expect the todo list. Edit the first todo.
        do {
            let backStack = workflowHost.rendering.value
            XCTAssertEqual(2, backStack.items.count)

            guard let _ = backStack.items[0].screen.wrappedScreen as? WelcomeScreen else {
                XCTFail("Expected first screen of `WelcomeScreen`")
                return
            }

            guard let todoScreen = backStack.items[1].screen.wrappedScreen as? TodoListScreen else {
                XCTFail("Expected second screen of `TodoListScreen`")
                return
            }
            XCTAssertEqual(1, todoScreen.todoTitles.count)
            // Select the first todo:
            todoScreen.onTodoSelected(0)
        }

        // Selected a todo to edit. Expect the todo edit screen.
        do {
            let backStack = workflowHost.rendering.value
            XCTAssertEqual(3, backStack.items.count)

            guard let _ = backStack.items[0].screen.wrappedScreen as? WelcomeScreen else {
                XCTFail("Expected first screen of `WelcomeScreen`")
                return
            }

            guard let _ = backStack.items[1].screen.wrappedScreen as? TodoListScreen else {
                XCTFail("Expected second screen of `TodoListScreen`")
                return
            }

            guard let editScreen = backStack.items[2].screen.wrappedScreen as? TodoEditScreen else {
                XCTFail("Expected second screen of `TodoEditScreen`")
                return
            }

            // Update the title:
            editScreen.onTitleChanged("New Title")
        }

        // Save the selected todo.
        do {
            let backStack = workflowHost.rendering.value
            XCTAssertEqual(3, backStack.items.count)

            guard let _ = backStack.items[0].screen.wrappedScreen as? WelcomeScreen else {
                XCTFail("Expected first screen of `WelcomeScreen`")
                return
            }

            guard let _ = backStack.items[1].screen.wrappedScreen as? TodoListScreen else {
                XCTFail("Expected second screen of `TodoListScreen`")
                return
            }

            guard let _ = backStack.items[2].screen.wrappedScreen as? TodoEditScreen else {
                XCTFail("Expected second screen of `TodoEditScreen`")
                return
            }

            // Save the changes by tapping the right bar button.
            // This also validates that the navigation bar was described as expected.
            switch backStack.items[2].barVisibility {
            case .hidden:
                XCTFail("Expected a visible navigation bar")

            case .visible(let barContent):
                switch barContent.rightItem {
                case .none:
                    XCTFail("Expected a right bar button")

                case .button(let button):

                    switch button.content {
                    case .text(let text):
                        XCTAssertEqual("Save", text)

                    case .icon:
                        XCTFail("Expected the right bar button to have a title of `Save`")
                    }
                    // Tap the right bar button to save.
                    button.handler()
                }
            }
        }

        // Expect the todo list. Validate the title was updated.
        do {
            let backStack = workflowHost.rendering.value
            XCTAssertEqual(2, backStack.items.count)

            guard let _ = backStack.items[0].screen.wrappedScreen as? WelcomeScreen else {
                XCTFail("Expected first screen of `WelcomeScreen`")
                return
            }

            guard let todoScreen = backStack.items[1].screen.wrappedScreen as? TodoListScreen else {
                XCTFail("Expected second screen of `TodoListScreen`")
                return
            }
            XCTAssertEqual(1, todoScreen.todoTitles.count)
            XCTAssertEqual("New Title", todoScreen.todoTitles[0])
        }
    }
}
