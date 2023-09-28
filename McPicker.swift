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

open class AXPPicker: UIView {

    open var fontSize: CGFloat = 25.0
    open var backgroundColorAlpha: CGFloat?
    open var label: UILabel?

    public var pickerBackgroundColor: UIColor? {
        didSet { picker.backgroundColor = pickerBackgroundColor }
    }
    public var pickerSelectRowsForComponents: [Int: [Int: Bool]]? {
        didSet {
            for component in pickerSelectRowsForComponents!.keys {
                if let row = pickerSelectRowsForComponents![component]?.keys.first,
                    let isAnimated = pickerSelectRowsForComponents![component]?.values.first {
                    pickerSelection[component] = pickerData[component][row]
                    picker.selectRow(row, inComponent: component, animated: isAnimated)
                }
            }
        }
    }
    public var showsSelectionIndicator: Bool? {
        didSet { picker.showsSelectionIndicator = showsSelectionIndicator ?? false }
    }

    public typealias SelectionChangedHandler = ((_ selections: [Int:String], _ componentThatChanged: Int) -> Void)

    internal var popOverContentSize: CGSize {
        return CGSize(width: 120, height: Constant.pickerHeight)
    }
    internal var _backgroundColorAlpha: CGFloat {
        return self.backgroundColorAlpha ?? Constant.backgroundColorAlpha
    }
    internal var pickerSelection: [Int:String] = [:]
    internal var pickerData: [[String]] = []
    internal var numberOfComponents: Int {
        return pickerData.count
    }
    internal let picker: UIPickerView = UIPickerView()
    internal let backgroundView: UIView = UIView()
    internal var isPopoverMode = false
    internal var axpPickerPopoverViewController: AXPPickerPopoverViewController?
    internal enum AnimationDirection {
        case `in`, out // swiftlint:disable:this identifier_name
    }
    internal enum Constant {
        static let backgroundColorAlpha: CGFloat =  0.75
        static let pickerHeight: CGFloat = 216.0
        static let toolBarHeight: CGFloat = 44.0
        static let animationSpeed: TimeInterval = 0.25
        static let barButtonFixedSpacePadding: CGFloat = 0.02
    }

    fileprivate var selectionChangedHandler: SelectionChangedHandler?

    private var appWindow: UIWindow {
        guard let window = UIApplication.shared.keyWindow else {
            debugPrint("KeyWindow not set. Returning a default window for unit testing.")
            return UIWindow()
        }
        return window
    }

    convenience public init(data: [[String]]) {
        self.init(frame: CGRect.zero)
        self.pickerData = data
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    internal override init(frame: CGRect) {
        super.init(frame: frame)
    }
    // MARK: Show As Popover
    open class func showAsPopover(data: [[String]],
                                  fromViewController: UIViewController,
                                  sourceView: UIView? = nil,
                                  sourceRect: CGRect? = nil,
                                  selectionChangedHandler: SelectionChangedHandler? = nil) {
        AXPPicker(data: data).showAsPopover(fromViewController: fromViewController,
                                           sourceView: sourceView,
                                           sourceRect: sourceRect,
                                           selectionChangedHandler: selectionChangedHandler)
    }


    open func showAsPopover(fromViewController: UIViewController,
                            sourceView: UIView? = nil,
                            sourceRect: CGRect? = nil,
                            selectionChangedHandler: SelectionChangedHandler? = nil) {

        if sourceView == nil {
            fatalError("You must set at least sourceView")
        }

        self.isPopoverMode = true
        self.selectionChangedHandler = selectionChangedHandler

        axpPickerPopoverViewController = AXPPickerPopoverViewController(axpPicker: self)
        axpPickerPopoverViewController?.modalPresentationStyle = UIModalPresentationStyle.popover

        let popover = axpPickerPopoverViewController?.popoverPresentationController
        popover?.delegate = self

        if let sView = sourceView {
            popover?.sourceView = sView
            popover?.sourceRect = sourceRect ?? sView.bounds
        }
        fromViewController.present(axpPickerPopoverViewController!, animated: true)
    }

    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(AXPPicker.sizeViews), name: UIDevice.orientationDidChangeNotification, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }

    @objc internal func sizeViews() {
        let size = isPopoverMode ? popOverContentSize : self.appWindow.bounds.size
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        backgroundView.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: Constant.pickerHeight)
        picker.frame = CGRect(x: 0, y: 0, width: backgroundView.bounds.size.width, height: Constant.pickerHeight)
    }

    internal func addAllSubviews() {
        backgroundView.addSubview(picker)
        self.addSubview(backgroundView)
    }

    internal func dismissViews() {
        if isPopoverMode {
            axpPickerPopoverViewController?.dismiss(animated: true, completion: nil)
            axpPickerPopoverViewController = nil // Release, as to not create a retain cycle.
        } else {
            animateViews(direction: .out)
        }
    }

    internal func animateViews(direction: AnimationDirection) {
        var backgroundFrame = backgroundView.frame
        let animateColor = self.backgroundColor ?? .black

        if direction == .in {
            // Start transparent
            //
            self.backgroundColor = animateColor.withAlphaComponent(0)

            // Start picker off the bottom of the screen
            //
            backgroundFrame.origin.y = self.appWindow.bounds.size.height
            backgroundView.frame = backgroundFrame

            // Add views
            //
            addAllSubviews()
            appWindow.addSubview(self)

            // Animate things on screen
            //
            UIView.animate(withDuration: Constant.animationSpeed, animations: {
                self.backgroundColor = animateColor.withAlphaComponent(self._backgroundColorAlpha)
                backgroundFrame.origin.y = self.appWindow.bounds.size.height - self.backgroundView.bounds.height
                self.backgroundView.frame = backgroundFrame
            })
        } else {
            // Animate things off screen
            //
            UIView.animate(withDuration: Constant.animationSpeed, animations: {
                self.backgroundColor = animateColor.withAlphaComponent(0)
                backgroundFrame.origin.y = self.appWindow.bounds.size.height
                self.backgroundView.frame = backgroundFrame
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }

    @objc internal func cancel() {
        self.dismissViews()
    }

    public func setup() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AXPPicker.cancel))
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
        backgroundView.backgroundColor = UIColor.white
        picker.delegate = self
        picker.dataSource = self
        sizeViews()
        for (index, element) in pickerData.enumerated() {
            pickerSelection[index] = element.first
        }
    }
}

extension AXPPicker : UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return self.numberOfComponents
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
}

extension AXPPicker : UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel

        if pickerLabel == nil {
            pickerLabel = UILabel()

            if let goodLabel = label {
                pickerLabel?.textAlignment = goodLabel.textAlignment
                pickerLabel?.font = goodLabel.font
                pickerLabel?.textColor = goodLabel.textColor
                pickerLabel?.backgroundColor = goodLabel.backgroundColor
                pickerLabel?.numberOfLines = goodLabel.numberOfLines
            } else {
                pickerLabel?.textAlignment = .center
                pickerLabel?.font = UIFont.systemFont(ofSize: self.fontSize)
            }
        }

        pickerLabel?.text = pickerData[component][row]

        return pickerLabel!
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
         if !pickerData[component].isEmpty {
            self.pickerSelection[component] = pickerData[component][row]
            self.selectionChangedHandler?(self.pickerSelection, component)
            self.dismissViews()
        }
    }
}

extension AXPPicker : UIPopoverPresentationControllerDelegate {
    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // This *forces* a popover to be displayed on the iPhone
        return .none
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // This *forces* a popover to be displayed on the iPhone X Plus
        return .none
    }
}

extension AXPPicker : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let goodView = touch.view {
            return goodView == self
        }
        return false
    }
}
