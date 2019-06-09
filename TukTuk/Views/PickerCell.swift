//
//  PickerCell.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

import UIKit

class PickerCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var picker: UIPickerView!

    class NoSelection: Titled {
        var title: String = .emptyTitle
    }

    var data: [Titled] = []
    var canBeEmpty = true
    var adjustedData: [Titled] {
        if canBeEmpty {
            return [NoSelection()] + data
        } else {
            return data
        }
    }

    var select: (Titled?) -> () = {_ in }
}

extension PickerCell: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return adjustedData.count
    }
}

extension PickerCell: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return adjustedData[row].title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedRow = adjustedData[row]
        self.picker.isHidden = true
        self.detail.text = selectedRow.title
        if selectedRow as? NoSelection == nil {
            select(selectedRow)
        } else {
            select(nil)
        }
    }

    func showPicker() {
        picker.isHidden = false
        if let index = adjustedData.firstIndex(where: { $0.title == self.detail.text}) {
            picker.selectRow(index, inComponent: 0, animated: true)
        }
    }

    func hidePicker() {
        picker.isHidden = true
    }
}
