import SwiftUI

struct CurrencyTextField: UIViewRepresentable {
    @Binding var value: Double

    private let formatter: NumberFormatter

    init(value: Binding<Double>) {
        self._value = value
        self.formatter = NumberFormatter()
        self.formatter.numberStyle = .currency
        self.formatter.maximumFractionDigits = 2
        self.formatter.minimumFractionDigits = 2
        self.formatter.currencySymbol = "$"
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.delegate = context.coordinator
        textField.textAlignment = .right // Ensure right alignment
        textField.text = formatter.string(from: NSNumber(value: value))
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = formatter.string(from: NSNumber(value: value))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, formatter: formatter)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var value: Double
        private let formatter: NumberFormatter

        init(value: Binding<Double>, formatter: NumberFormatter) {
            self._value = value
            self.formatter = formatter
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            let text = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            let sanitizedText = text.replacingOccurrences(of: formatter.currencySymbol, with: "")
                .replacingOccurrences(of: formatter.groupingSeparator, with: "")
                .replacingOccurrences(of: formatter.decimalSeparator, with: "")
            
            if let number = Double(sanitizedText) {
                value = number / 100
                textField.text = formatter.string(from: NSNumber(value: value))
            } else {
                value = 0
                textField.text = formatter.string(from: 0)
            }
            return false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if let text = textField.text, let number = formatter.number(from: text) {
                value = number.doubleValue
            } else {
                value = 0
            }
            textField.text = formatter.string(from: NSNumber(value: value))
        }
    }
}
