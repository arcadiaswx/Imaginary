import Foundation
import Cache

extension ImageView {
  /// Set image with url
  ///
  /// - Parameters:
  ///   - url: The url to fetch
  ///   - placeholder: Placeholder if any
  ///   - option: Customise this specific fetching
  ///   - completion: Called after done
  public func setImage(url: URL,
                       placeholder: Image? = nil,
                       option: Option = Option(),
                       completion: Completion? = nil) {
    if let placeholder = placeholder {
      image = placeholder
    }

    if let imageFetcher = imageFetcher {
      imageFetcher.cancel()
      self.imageFetcher = nil
    }

    self.imageFetcher = option.fetcherMaker()
    self.imageFetcher?.fetch(url: url, completion: { [weak self] result in
      guard let `self` = self else {
        return
      }

      self.handle(url: url, result: result,
                  option: option, completion: completion)
    })
  }

  private func handle(url: URL, result: Result,
                      option: Option, completion: Completion?) {

    defer {
      DispatchQueue.main.async {
        completion?(result)
      }
    }

    switch result {
    case .value(let image):
      let processedImage = option.imagePreprocessor?.process(image: image) ?? image
      DispatchQueue.main.async {
        option.imageDisplayer.display(image: processedImage, onto: self)
      }
    case .error(let error):
      Configuration.trackError?(url, error)
    }
  }

  private var imageFetcher: ImageFetcher? {
    get {
      return objc_getAssociatedObject(
        self, &AssociateKey.fetcher) as? ImageFetcher
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociateKey.fetcher,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }
}

/// Used to associate ImageFetcher with ImageView
fileprivate struct AssociateKey {
  static var fetcher = 0
}
