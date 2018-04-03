//
// MNIST.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class MNISTInput : MLFeatureProvider {

    /// Image to analyze as grayscale (kCVPixelFormatType_OneComponent8) image buffer, 28 pixels wide by 28 pixels high
    var image: CVPixelBuffer
    
    public var featureNames: Set<String> {
        get {
            return ["image"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "image") {
            return MLFeatureValue(pixelBuffer: image)
        }
        return nil
    }
    
    public init(image: CVPixelBuffer) {
        self.image = image
    }
}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class MNISTOutput : MLFeatureProvider {

    /// Array of predictions mapped to their indices as dictionary of 64-bit integers to doubles
    public let prediction: [Int64 : Double]

    /// classLabel as integer value
    public let classLabel: Int64
    
    public var featureNames: Set<String> {
        get {
            return ["prediction", "classLabel"]
        }
    }
    
    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "prediction") {
            return try! MLFeatureValue(dictionary: prediction as [NSObject : NSNumber])
        }
        if (featureName == "classLabel") {
            return MLFeatureValue(int64: classLabel)
        }
        return nil
    }
    
    public init(prediction: [Int64 : Double], classLabel: Int64) {
        self.prediction = prediction
        self.classLabel = classLabel
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class MNIST {
    var model: MLModel

    /**
        Construct a model with explicit path to mlmodel file
        - parameters:
           - url: the file url of the model
           - throws: an NSError object that describes the problem
    */
    public init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /// Construct a model that automatically loads the model from the app's bundle
    public convenience init() {
        let bundle = Bundle(for: MNIST.self)
        let assetPath = bundle.url(forResource: "MNIST", withExtension:"mlmodelc")
        try! self.init(contentsOf: assetPath!)
    }

    /**
        Make a prediction using the structured interface
        - parameters:
           - input: the input to the prediction as MNISTInput
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as MNISTOutput
    */
    public func prediction(input: MNISTInput) throws -> MNISTOutput {
        let outFeatures = try model.prediction(from: input)
        let result = MNISTOutput(prediction: outFeatures.featureValue(for: "prediction")!.dictionaryValue as! [Int64 : Double], classLabel: outFeatures.featureValue(for: "classLabel")!.int64Value)
        return result
    }

    /**
        Make a prediction using the convenience interface
        - parameters:
            - image: Image to analyze as grayscale (kCVPixelFormatType_OneComponent8) image buffer, 28 pixels wide by 28 pixels high
        - throws: an NSError object that describes the problem
        - returns: the result of the prediction as MNISTOutput
    */
    public func prediction(image: CVPixelBuffer) throws -> MNISTOutput {
        let input_ = MNISTInput(image: image)
        return try self.prediction(input: input_)
    }
}
