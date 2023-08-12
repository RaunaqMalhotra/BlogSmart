//
//  TermsAndConditionsViewController.swift
//  BlogSmart
//
//  Created by Raunaq Malhotra on 8/10/23.
//

import UIKit
import PDFKit

class TermsAndConditionsViewController: UIViewController {

    var pdfURL: URL?
        
    convenience init(url: URL) {
        self.init()
        self.pdfURL = url
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let pdfURL = pdfURL {
            let pdfView = PDFView(frame: view.bounds)
            pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pdfView.document = PDFDocument(url: pdfURL)
            view.addSubview(pdfView)
        }
    }

}
