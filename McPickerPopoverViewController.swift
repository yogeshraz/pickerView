/*
 Copyright (c) 2017-2020 Kevin McGill <kevin@mcgilldevtech.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import UIKit

internal class AXPPickerPopoverViewController: UIViewController {

    weak var axpPicker: AXPPicker?
    internal var safeArea: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaInsets
        }
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    internal convenience init(axpPicker: AXPPicker) {
        self.init(nibName: nil, bundle: nil)
        self.axpPicker = axpPicker
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        axpPicker!.sizeViews()
        axpPicker!.addAllSubviews()
        self.view.addSubview(axpPicker!)
        self.preferredContentSize = axpPicker!.popOverContentSize
    }

    override func viewSafeAreaInsetsDidChange() {
        self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: self.preferredContentSize.height - safeArea.top)
    }
}
