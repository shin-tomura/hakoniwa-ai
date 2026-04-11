import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

enum ActivationType { sigmoid, relu, tanh }

enum OptimizerType { sgd, miniBatch, adam }

// 可視化用に層データをラップするクラス
class Layer {
  final List<List<double>> weights;
  Layer(this.weights);
}

// ======================================================================
// 1. ニューラルネットワーク（NN）計算エンジン
// ======================================================================
class NeuralNetwork {
  late final List<int> layerSizes;
  double learningRate;
  final ActivationType hiddenActivation;

  final OptimizerType optimizerType;
  final int batchSize;

  // 損失関数のタイプ (0: MSE, 1: CrossEntropy)
  final int lossType;

  // NN強化用パラメータ
  final double dropoutRate;
  final double l2Rate;

  // ★ V3 追加：VAE用パラメータ
  final bool isVAE;
  final int latentDim; // 潜在空間(Z)の次元数
  double klLoss = 0.0; // 表示用のKL損失保持

  late List<List<List<double>>> weights;
  late List<List<double>> biases;

  // VAE用の特殊な層（Z層の分散表現用。平均muは通常のweightsを流用）
  List<List<double>>? logVarWeights;
  List<double>? logVarBiases;

  // ドロップアウト用のマスク保持（バックプロパゲーション用）
  List<List<double>>? _currentDropoutMasks;

  List<Layer> get layers {
    return weights.map((w) => Layer(w)).toList();
  }

  // Adam用パラメータ
  late List<List<List<double>>> mW, vW;
  late List<List<double>> mB, vB;

  // VAE用Adamパラメータ (logVar専用)
  List<List<double>>? mLogVarW, vLogVarW;
  List<double>? mLogVarB, vLogVarB;

  int t = 0;

  final Random _rand = Random();

  final Stopwatch _yieldTimer = Stopwatch()..start();
  final Stopwatch _coolDownTimer = Stopwatch()..start();

  NeuralNetwork({
    required List<int> layerSizes,
    this.learningRate = 0.1,
    this.hiddenActivation = ActivationType.relu,
    this.optimizerType = OptimizerType.adam,
    this.batchSize = 8,
    this.lossType = 0,
    this.dropoutRate = 0.0,
    this.l2Rate = 0.0,
    this.isVAE = false,
    this.latentDim = 4,
    bool isFromJson = false, // jsonからの復元時は構造を変えないためのフラグ
  }) {
    this.layerSizes = [];

    // ★ 修正：VAEモードなら自動的に対称的な「砂時計型」のアーキテクチャを構築する
    if (isVAE && !isFromJson) {
      int inSize = layerSizes.first;
      int outSize = layerSizes.last;
      // ユーザーが設定した隠れ層をエンコーダとする
      List<int> enc = layerSizes.sublist(1, layerSizes.length - 1);

      this.layerSizes.add(inSize);
      this.layerSizes.addAll(enc);
      this.layerSizes.add(latentDim); // ボトルネック（Z層）
      this.layerSizes.addAll(enc.reversed); // デコーダは逆順
      this.layerSizes.add(outSize);
    } else {
      this.layerSizes.addAll(layerSizes);
    }

    weights = [];
    biases = [];
    mW = [];
    vW = [];
    mB = [];
    vB = [];

    // Z層のインデックスを計算
    int zLayerIdx = isVAE ? (this.layerSizes.length - 3) ~/ 2 : -1;

    // ネットワーク初期化
    for (int i = 0; i < this.layerSizes.length - 1; i++) {
      int inSize = this.layerSizes[i];
      int outSize = this.layerSizes[i + 1];

      // ★ 変更箇所：隠れ層の活性化関数に合わせて初期化の計算を分岐
      double limit;
      if (hiddenActivation == ActivationType.relu) {
        // ReLU (Leaky ReLU) の場合は Heの初期化（一様分布）
        limit = sqrt(6 / inSize);
      } else {
        // Sigmoid, Tanh の場合は従来の Xavierの初期化（一様分布）
        limit = sqrt(6 / (inSize + outSize));
      }

      weights.add(
        List.generate(
          inSize,
          (_) => List.generate(
            outSize,
            (_) => (_rand.nextDouble() * 2 - 1) * limit,
          ),
        ),
      );
      biases.add(List.generate(outSize, (_) => 0.0));

      // Adamの初期化
      mW.add(List.generate(inSize, (_) => List.filled(outSize, 0.0)));
      vW.add(List.generate(inSize, (_) => List.filled(outSize, 0.0)));
      mB.add(List.filled(outSize, 0.0));
      vB.add(List.filled(outSize, 0.0));

      // VAEのボトルネック層の場合、分散(logVar)用の並行ネットワークも作る
      if (isVAE && i == zLayerIdx) {
        logVarWeights = List.generate(
          inSize,
          (_) => List.generate(
            latentDim,
            (_) => (_rand.nextDouble() * 2 - 1) * limit,
          ),
        );
        logVarBiases = List.generate(latentDim, (_) => 0.0);

        mLogVarW = List.generate(inSize, (_) => List.filled(latentDim, 0.0));
        vLogVarW = List.generate(inSize, (_) => List.filled(latentDim, 0.0));
        mLogVarB = List.filled(latentDim, 0.0);
        vLogVarB = List.filled(latentDim, 0.0);
      }
    }
  }

  Map<String, dynamic> toJson() {
    List<double> flatWeights = [];
    for (var layer in weights) {
      for (var node in layer) {
        flatWeights.addAll(node);
      }
    }
    String wBase64 = base64Encode(
      Float64List.fromList(flatWeights).buffer.asUint8List(),
    );

    List<double> flatBiases = [];
    for (var layer in biases) {
      flatBiases.addAll(layer);
    }
    String bBase64 = base64Encode(
      Float64List.fromList(flatBiases).buffer.asUint8List(),
    );

    // VAE用の保存 (logVarのみ追加保存。muは通常のweightsとして保存されている)
    String? logWBase64, logBBase64;
    if (isVAE) {
      List<double> fLogW = [];
      for (var node in logVarWeights!) fLogW.addAll(node);
      logWBase64 = base64Encode(
        Float64List.fromList(fLogW).buffer.asUint8List(),
      );
      logBBase64 = base64Encode(
        Float64List.fromList(logVarBiases!).buffer.asUint8List(),
      );
    }

    return {
      'layerSizes': layerSizes,
      'learningRate': learningRate,
      'hiddenActivation': hiddenActivation.index,
      'optimizerType': optimizerType.index,
      'lossType': lossType,
      'dropoutRate': dropoutRate,
      'l2Rate': l2Rate,
      'weights_bin': wBase64,
      'biases_bin': bBase64,
      'isVAE': isVAE,
      'latentDim': latentDim,
      'logW_bin': logWBase64,
      'logB_bin': logBBase64,
    };
  }

  factory NeuralNetwork.fromJson(Map<String, dynamic> json) {
    var nn = NeuralNetwork(
      layerSizes: List<int>.from(json['layerSizes']),
      learningRate: (json['learningRate'] as num).toDouble(),
      hiddenActivation: ActivationType.values[json['hiddenActivation'] as int],
      optimizerType: json.containsKey('optimizerType')
          ? OptimizerType.values[json['optimizerType'] as int]
          : OptimizerType.sgd,
      lossType: json['lossType'] ?? 0,
      dropoutRate: (json['dropoutRate'] as num?)?.toDouble() ?? 0.0,
      l2Rate: (json['l2Rate'] as num?)?.toDouble() ?? 0.0,
      isVAE: json['isVAE'] ?? false,
      latentDim: json['latentDim'] ?? 4,
      isFromJson: true, // 復元時は構造を再計算しない
    );

    if (json.containsKey('weights_bin')) {
      Float64List flatW = base64Decode(
        json['weights_bin'],
      ).buffer.asFloat64List();
      int ptrW = 0;
      for (int l = 0; l < nn.weights.length; l++) {
        for (int k = 0; k < nn.weights[l].length; k++) {
          for (int j = 0; j < nn.weights[l][k].length; j++) {
            nn.weights[l][k][j] = flatW[ptrW++];
          }
        }
      }
      Float64List flatB = base64Decode(
        json['biases_bin'],
      ).buffer.asFloat64List();
      int ptrB = 0;
      for (int l = 0; l < nn.biases.length; l++) {
        for (int j = 0; j < nn.biases[l].length; j++) {
          nn.biases[l][j] = flatB[ptrB++];
        }
      }
    }

    // VAE復元
    if (nn.isVAE && json.containsKey('logW_bin')) {
      int zLayerIdx = (nn.layerSizes.length - 3) ~/ 2;
      int eSize = nn.layerSizes[zLayerIdx];

      Float64List fLogW = base64Decode(json['logW_bin']).buffer.asFloat64List();
      Float64List fLogB = base64Decode(json['logB_bin']).buffer.asFloat64List();

      nn.logVarWeights = List.generate(
        eSize,
        (_) => List.filled(nn.latentDim, 0.0),
      );
      nn.logVarBiases = List.filled(nn.latentDim, 0.0);

      int p1 = 0, p2 = 0;
      for (int i = 0; i < eSize; i++) {
        for (int j = 0; j < nn.latentDim; j++) {
          nn.logVarWeights![i][j] = fLogW[p1++];
        }
      }
      for (int j = 0; j < nn.latentDim; j++) {
        nn.logVarBiases![j] = fLogB[p2++];
      }

      nn.mLogVarW = List.generate(eSize, (_) => List.filled(nn.latentDim, 0.0));
      nn.vLogVarW = List.generate(eSize, (_) => List.filled(nn.latentDim, 0.0));
      nn.mLogVarB = List.filled(nn.latentDim, 0.0);
      nn.vLogVarB = List.filled(nn.latentDim, 0.0);
    }

    return nn;
  }

  double _activate(double x, ActivationType type) {
    switch (type) {
      case ActivationType.relu:
        return x > 0 ? x : 0.01 * x;
      case ActivationType.tanh:
        return (exp(x) - exp(-x)) / (exp(x) + exp(-x));
      case ActivationType.sigmoid:
        return 1.0 / (1.0 + exp(-x));
    }
  }

  double _derivative(double val, ActivationType type) {
    switch (type) {
      case ActivationType.relu:
        return val > 0 ? 1.0 : 0.01;
      case ActivationType.tanh:
        return 1.0 - val * val;
      case ActivationType.sigmoid:
        return val * (1.0 - val);
    }
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  List<double> _softmax(List<double> x) {
    double maxVal = x.reduce(max);
    double sum = 0.0;
    List<double> exps = List.filled(x.length, 0.0);
    for (int i = 0; i < x.length; i++) {
      exps[i] = exp(x[i] - maxVal);
      sum += exps[i];
    }
    for (int i = 0; i < x.length; i++) {
      exps[i] /= sum;
    }
    return exps;
  }

  // Box-Muller変換
  double _randomNormal() {
    double u1 = 1.0 - _rand.nextDouble();
    double u2 = 1.0 - _rand.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }

  Map<String, dynamic> _forwardExtended(
    List<double> input, {
    bool isTraining = false,
  }) {
    List<List<double>> acts = [input];
    if (isTraining) _currentDropoutMasks = [];

    List<double> mu = [];
    List<double> logVar = [];
    List<double> epsilon = [];

    int zLayerIdx = isVAE ? (layerSizes.length - 3) ~/ 2 : -1;

    for (int l = 0; l < weights.length; l++) {
      List<double> prev = acts[l];
      List<double> next = List.filled(layerSizes[l + 1], 0.0);

      // ★ VAE ボトルネック層
      if (isVAE && l == zLayerIdx) {
        mu = List.filled(latentDim, 0.0);
        logVar = List.filled(latentDim, 0.0);

        for (int j = 0; j < latentDim; j++) {
          double sumMu = biases[l][j];
          double sumLogVar = logVarBiases![j];
          for (int k = 0; k < layerSizes[l]; k++) {
            sumMu += prev[k] * weights[l][k][j]; // weights[l] が mu を担当
            sumLogVar += prev[k] * logVarWeights![k][j];
          }
          mu[j] = sumMu;
          logVar[j] = sumLogVar;
        }

        // 爆発防止のためのClamp処理
        epsilon = List.generate(
          latentDim,
          (_) => isTraining ? _randomNormal() : 0.0,
        );
        for (int j = 0; j < latentDim; j++) {
          double std = exp(0.5 * logVar[j].clamp(-20.0, 10.0));
          next[j] = mu[j] + std * epsilon[j];
        }

        if (isTraining)
          _currentDropoutMasks!.add(
            List.filled(latentDim, 1.0),
          ); // Z層はドロップアウトしない
        acts.add(next);
        continue;
      }

      // 通常の層の計算
      for (int j = 0; j < layerSizes[l + 1]; j++) {
        double sum = biases[l][j];
        for (int k = 0; k < layerSizes[l]; k++) {
          sum += prev[k] * weights[l][k][j];
        }
        next[j] = sum;
      }

      if (l == weights.length - 1) {
        // 出力層
        if (lossType == 1 && !isVAE) {
          next = _softmax(next);
        } else {
          for (int j = 0; j < next.length; j++) next[j] = _sigmoid(next[j]);
        }
      } else {
        // 隠れ層：活性化関数適用 ＆ ドロップアウト
        List<double> mask = List.filled(next.length, 1.0);
        double keepProb = 1.0 - dropoutRate;
        for (int j = 0; j < next.length; j++) {
          next[j] = _activate(next[j], hiddenActivation);

          if (isTraining && dropoutRate > 0.0) {
            if (_rand.nextDouble() < dropoutRate) {
              mask[j] = 0.0;
              next[j] = 0.0;
            } else {
              next[j] /= keepProb;
            }
          }
        }
        if (isTraining) _currentDropoutMasks!.add(mask);
      }
      acts.add(next);
    }

    return {
      'activations': acts,
      'mu': mu,
      'logVar': logVar,
      'epsilon': epsilon,
    };
  }

  List<List<double>> _forward(List<double> input, {bool isTraining = false}) {
    return _forwardExtended(input, isTraining: isTraining)['activations'];
  }

  Future<double> trainEpoch(
    List<List<double>> inputs,
    List<List<double>> expectedOutputs,
    int ecoWaitMs,
    bool Function()? isCancelled,
    Future<void> Function()? onRapidUpdate,
  ) async {
    if (inputs.isEmpty) return 0.0;
    double totalReconLoss = 0.0;
    double totalKLLoss = 0.0;

    List<List<List<double>>> gradW = List.generate(
      weights.length,
      (l) => List.generate(
        layerSizes[l],
        (i) => List.filled(layerSizes[l + 1], 0.0),
      ),
    );
    List<List<double>> gradB = List.generate(
      biases.length,
      (l) => List.filled(layerSizes[l + 1], 0.0),
    );

    int zLayerIdx = isVAE ? (layerSizes.length - 3) ~/ 2 : -1;

    // VAE用勾配
    List<List<double>>? gradLogVarW;
    List<double>? gradLogVarB;
    if (isVAE) {
      int eSize = layerSizes[zLayerIdx];
      gradLogVarW = List.generate(eSize, (_) => List.filled(latentDim, 0.0));
      gradLogVarB = List.filled(latentDim, 0.0);
    }

    int currentBatchSize = 0;
    int bSize = (optimizerType == OptimizerType.sgd) ? 1 : batchSize;

    for (int i = 0; i < inputs.length; i++) {
      if (isCancelled != null && isCancelled()) {
        double currentLoss = i > 0 ? (totalReconLoss + totalKLLoss) / i : 0.0;
        return currentLoss / layerSizes.last; // ★修正
      }

      List<double> x = inputs[i];
      // VAEの場合は入力画像をそのまま正解データにする
      List<double> y = isVAE ? inputs[i] : expectedOutputs[i];

      var fResult = _forwardExtended(x, isTraining: true);
      List<List<double>> activations = fResult['activations'];
      List<double> mu = fResult['mu'];
      List<double> logVar = fResult['logVar'];
      List<double> epsilon = fResult['epsilon'];

      List<double> o = activations.last;

      List<List<double>> deltas = List.generate(
        weights.length,
        (idx) => List.filled(layerSizes[idx + 1], 0.0),
      );

      // 1. 出力層のデルタ
      for (int j = 0; j < o.length; j++) {
        if (lossType == 1 || isVAE) {
          // 画像はBCEの方が綺麗に学習できる
          totalReconLoss +=
              -(y[j] * log(o[j] + 1e-7) +
                  (1.0 - y[j]) * log(1.0 - o[j] + 1e-7));
          deltas.last[j] = o[j] - y[j];
        } else {
          totalReconLoss += pow(y[j] - o[j], 2);
          deltas.last[j] = (o[j] - y[j]) * o[j] * (1.0 - o[j]);
        }
      }

      if (isVAE) {
        double kl = 0.0;
        for (int j = 0; j < latentDim; j++) {
          kl +=
              -0.5 *
              (1 +
                  logVar[j] -
                  pow(mu[j], 2) -
                  exp(logVar[j].clamp(-20.0, 10.0)));
        }
        totalKLLoss += kl;
      }

      List<double>? currentDeltasLogVar;

      // 2. 誤差逆伝播
      for (int l = weights.length - 2; l >= 0; l--) {
        // ★ VAEボトルネック層の特殊な逆伝播
        if (isVAE && l == zLayerIdx) {
          currentDeltasLogVar = List.filled(latentDim, 0.0);
          for (int j = 0; j < latentDim; j++) {
            double sum = 0.0;
            for (int k = 0; k < layerSizes[l + 2]; k++) {
              sum += deltas[l + 1][k] * weights[l + 1][j][k];
            }
            // Z層の勾配計算とKLのペナルティ付加
            double dMu = sum + mu[j];
            double std = exp(0.5 * logVar[j].clamp(-20.0, 10.0));
            double dLogVar =
                sum * 0.5 * std * epsilon[j] +
                0.5 * (exp(logVar[j].clamp(-20.0, 10.0)) - 1.0);

            // 勾配爆発を防ぐ
            deltas[l][j] = dMu.clamp(-10.0, 10.0);
            currentDeltasLogVar[j] = dLogVar.clamp(-10.0, 10.0);
          }
          continue;
        }

        // 通常の逆伝播
        for (int j = 0; j < layerSizes[l + 1]; j++) {
          double sum = 0.0;
          if (isVAE && l == zLayerIdx - 1) {
            // ボトルネック手前の層は、muとlogVarの両方から誤差を受け取る
            for (int k = 0; k < latentDim; k++) {
              sum +=
                  deltas[l + 1][k] * weights[l + 1][j][k] +
                  currentDeltasLogVar![k] * logVarWeights![j][k];
            }
          } else {
            for (int k = 0; k < layerSizes[l + 2]; k++) {
              sum += deltas[l + 1][k] * weights[l + 1][j][k];
            }
          }

          double valForDerivative = activations[l + 1][j];
          if (dropoutRate > 0.0 &&
              _currentDropoutMasks != null &&
              _currentDropoutMasks![l][j] > 0.0) {
            valForDerivative *= (1.0 - dropoutRate);
          }

          double d = _derivative(valForDerivative, hiddenActivation);

          if (dropoutRate > 0.0 && _currentDropoutMasks != null) {
            d *= _currentDropoutMasks![l][j] / (1.0 - dropoutRate);
          }
          deltas[l][j] = sum * d;
        }
      }

      // 3. 勾配の蓄積
      for (int l = 0; l < weights.length; l++) {
        for (int j = 0; j < layerSizes[l + 1]; j++) {
          gradB[l][j] += deltas[l][j];
          if (isVAE && l == zLayerIdx) {
            gradLogVarB![j] += currentDeltasLogVar![j];
          }

          for (int k = 0; k < layerSizes[l]; k++) {
            gradW[l][k][j] +=
                (deltas[l][j] * activations[l][k]) +
                (l2Rate * weights[l][k][j]);
            if (isVAE && l == zLayerIdx) {
              gradLogVarW![k][j] +=
                  (currentDeltasLogVar![j] * activations[l][k]) +
                  (l2Rate * logVarWeights![k][j]);
            }
          }
        }
      }

      currentBatchSize++;

      if (currentBatchSize >= bSize || i == inputs.length - 1) {
        _applyGradients(gradW, gradB, currentBatchSize);

        if (isVAE) {
          _applyVAEGradients(gradLogVarW!, gradLogVarB!, currentBatchSize);
          int eSize = layerSizes[zLayerIdx];
          gradLogVarW = List.generate(
            eSize,
            (_) => List.filled(latentDim, 0.0),
          );
          gradLogVarB = List.filled(latentDim, 0.0);
        }

        gradW = List.generate(
          weights.length,
          (l) => List.generate(
            layerSizes[l],
            (idx) => List.filled(layerSizes[l + 1], 0.0),
          ),
        );
        gradB = List.generate(
          biases.length,
          (l) => List.filled(layerSizes[l + 1], 0.0),
        );
        currentBatchSize = 0;
      }

      if (_coolDownTimer.elapsedMilliseconds > 500) {
        if (ecoWaitMs > 0) {
          await Future.delayed(Duration(milliseconds: ecoWaitMs));
        } else {
          await Future.delayed(Duration.zero);
        }
        _coolDownTimer.reset();
        _yieldTimer.reset();

        if (isCancelled != null && isCancelled()) {
          double currentLoss = (totalReconLoss + totalKLLoss) / (i + 1);
          return currentLoss / layerSizes.last; // ★修正
        }
      } else if (_yieldTimer.elapsedMilliseconds > 14) {
        await Future.delayed(Duration.zero);
        _yieldTimer.reset();

        if (isCancelled != null && isCancelled()) {
          double currentLoss = (totalReconLoss + totalKLLoss) / (i + 1);
          return currentLoss / layerSizes.last; // ★修正
        }
      }
    }

    klLoss = inputs.isEmpty ? 0 : totalKLLoss / inputs.length;
    double finalLoss = (totalReconLoss + klLoss) / inputs.length;

    // ★ 全モード共通：出力要素数（画像なら768, テキストなら文字数）で割り、平均誤差にする
    int outputSize = layerSizes.last;
    return finalLoss / outputSize;
  }

  void _applyGradients(
    List<List<List<double>>> gradW,
    List<List<double>> gradB,
    int count,
  ) {
    if (optimizerType == OptimizerType.adam) t++;

    double beta1 = 0.9, beta2 = 0.999, epsilon = 1e-8;

    for (int l = 0; l < weights.length; l++) {
      for (int j = 0; j < layerSizes[l + 1]; j++) {
        double gB = gradB[l][j] / count;
        if (optimizerType == OptimizerType.adam) {
          mB[l][j] = beta1 * mB[l][j] + (1 - beta1) * gB;
          vB[l][j] = beta2 * vB[l][j] + (1 - beta2) * (gB * gB);
          double mHat = mB[l][j] / (1 - pow(beta1, t));
          double vHat = vB[l][j] / (1 - pow(beta2, t));
          biases[l][j] -= learningRate * mHat / (sqrt(vHat) + epsilon);
        } else {
          biases[l][j] -= learningRate * gB;
        }

        for (int k = 0; k < layerSizes[l]; k++) {
          double gW = gradW[l][k][j] / count;
          if (optimizerType == OptimizerType.adam) {
            mW[l][k][j] = beta1 * mW[l][k][j] + (1 - beta1) * gW;
            vW[l][k][j] = beta2 * vW[l][k][j] + (1 - beta2) * (gW * gW);
            double mHat = mW[l][k][j] / (1 - pow(beta1, t));
            double vHat = vW[l][k][j] / (1 - pow(beta2, t));
            weights[l][k][j] -= learningRate * mHat / (sqrt(vHat) + epsilon);
          } else {
            weights[l][k][j] -= learningRate * gW;
          }
        }
      }
    }
  }

  void _applyVAEGradients(
    List<List<double>> gradLogVarW,
    List<double> gradLogVarB,
    int count,
  ) {
    double beta1 = 0.9, beta2 = 0.999, epsilon = 1e-8;
    int zLayerIdx = (layerSizes.length - 3) ~/ 2;
    int eSize = layerSizes[zLayerIdx];

    for (int j = 0; j < latentDim; j++) {
      double gLogB = gradLogVarB[j] / count;

      if (optimizerType == OptimizerType.adam) {
        mLogVarB![j] = beta1 * mLogVarB![j] + (1 - beta1) * gLogB;
        vLogVarB![j] = beta2 * vLogVarB![j] + (1 - beta2) * (gLogB * gLogB);
        logVarBiases![j] -=
            learningRate *
            (mLogVarB![j] / (1 - pow(beta1, t))) /
            (sqrt(vLogVarB![j] / (1 - pow(beta2, t))) + epsilon);
      } else {
        logVarBiases![j] -= learningRate * gLogB;
      }

      for (int k = 0; k < eSize; k++) {
        double gLogW = gradLogVarW[k][j] / count;
        if (optimizerType == OptimizerType.adam) {
          mLogVarW![k][j] = beta1 * mLogVarW![k][j] + (1 - beta1) * gLogW;
          vLogVarW![k][j] =
              beta2 * vLogVarW![k][j] + (1 - beta2) * (gLogW * gLogW);
          logVarWeights![k][j] -=
              learningRate *
              (mLogVarW![k][j] / (1 - pow(beta1, t))) /
              (sqrt(vLogVarW![k][j] / (1 - pow(beta2, t))) + epsilon);
        } else {
          logVarWeights![k][j] -= learningRate * gLogW;
        }
      }
    }
  }

  double calculateLoss(
    List<List<double>> inputs,
    List<List<double>> expectedOutputs,
  ) {
    if (inputs.isEmpty) return 0.0;
    double totalLoss = 0.0;
    for (int i = 0; i < inputs.length; i++) {
      List<double> y = isVAE ? inputs[i] : expectedOutputs[i];
      List<double> o = _forward(inputs[i], isTraining: false).last;

      for (int j = 0; j < o.length; j++) {
        if (lossType == 1 || isVAE) {
          totalLoss +=
              -(y[j] * log(o[j] + 1e-7) +
                  (1.0 - y[j]) * log(1.0 - o[j] + 1e-7));
        } else {
          totalLoss += pow(y[j] - o[j], 2);
        }
      }
    }
    double finalLoss = totalLoss / inputs.length;

    // ★ 全モード共通：出力要素数で割り、平均誤差にする
    int outputSize = layerSizes.last;
    return finalLoss / outputSize;
  }

  List<double> predict(List<double> x) {
    return _forward(x, isTraining: false).last;
  }

  // ★ VAE推論用：デコーダのみのフォワードパス（首が繋がったので完璧に動きます！）
  List<double> decodeFromZ(List<double> z) {
    if (!isVAE) return predict(z);

    int zLayerIdx = (layerSizes.length - 3) ~/ 2;
    List<double> prev = z;

    // Z層の次の層から出力層まで計算
    for (int l = zLayerIdx + 1; l < weights.length; l++) {
      List<double> next = List.filled(layerSizes[l + 1], 0.0);
      for (int j = 0; j < layerSizes[l + 1]; j++) {
        double sum = biases[l][j];
        for (int k = 0; k < layerSizes[l]; k++) {
          sum += prev[k] * weights[l][k][j];
        }
        next[j] = sum;
      }

      if (l == weights.length - 1) {
        for (int j = 0; j < next.length; j++) next[j] = _sigmoid(next[j]);
      } else {
        for (int j = 0; j < next.length; j++)
          next[j] = _activate(next[j], hiddenActivation);
      }
      prev = next;
    }
    return prev;
  }
}

// ======================================================================
// 2. ランダムフォレスト（RF）計算エンジン
// (※前回から変更なし)
// ======================================================================

class TreeNode {
  int? featureIndex;
  double? threshold;
  TreeNode? left;
  TreeNode? right;
  List<double>? value;

  TreeNode({
    this.featureIndex,
    this.threshold,
    this.left,
    this.right,
    this.value,
  });

  Map<String, dynamic> toJson() => {
    'featureIndex': featureIndex,
    'threshold': threshold,
    'value': value,
    'left': left?.toJson(),
    'right': right?.toJson(),
  };

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode(
      featureIndex: json['featureIndex'],
      threshold: json['threshold']?.toDouble(),
      value: json['value'] != null
          ? List<double>.from(json['value'].map((x) => (x as num).toDouble()))
          : null,
      left: json['left'] != null ? TreeNode.fromJson(json['left']) : null,
      right: json['right'] != null ? TreeNode.fromJson(json['right']) : null,
    );
  }
}

class TreePath {
  final List<int> route;
  final List<double> treeOutput;
  TreePath(this.route, this.treeOutput);
}

class RFPrediction {
  final List<double> finalOutput;
  final List<TreePath> treePaths;
  RFPrediction(this.finalOutput, this.treePaths);
}

class DecisionTree {
  final int maxDepth;
  final int lossType;
  final int outputSize;
  TreeNode? root;

  DecisionTree({
    required this.maxDepth,
    required this.lossType,
    required this.outputSize,
  });

  Map<String, dynamic> toJson() => {
    'maxDepth': maxDepth,
    'lossType': lossType,
    'outputSize': outputSize,
    'root': root?.toJson(),
  };

  factory DecisionTree.fromJson(Map<String, dynamic> json) {
    var tree = DecisionTree(
      maxDepth: json['maxDepth'] ?? 3,
      lossType: json['lossType'] ?? 0,
      outputSize: json['outputSize'] ?? 1,
    );
    if (json['root'] != null) {
      tree.root = TreeNode.fromJson(json['root']);
    }
    return tree;
  }

  Future<void> train(
    List<List<double>> X,
    List<List<double>> Y,
    List<double> featureImportances,
    int ecoWaitMs,
    bool Function() isCancelled,
    Stopwatch yieldTimer,
    Stopwatch coolDownTimer,
  ) async {
    root = await _buildTree(
      X,
      Y,
      0,
      featureImportances,
      ecoWaitMs,
      isCancelled,
      yieldTimer,
      coolDownTimer,
    );
  }

  Future<TreeNode> _buildTree(
    List<List<double>> X,
    List<List<double>> Y,
    int depth,
    List<double> featureImportances,
    int ecoWaitMs,
    bool Function() isCancelled,
    Stopwatch yieldTimer,
    Stopwatch coolDownTimer,
  ) async {
    if (isCancelled()) {
      return TreeNode(value: _calculateLeafValue(Y));
    }

    if (coolDownTimer.elapsedMilliseconds > 500) {
      if (ecoWaitMs > 0) {
        await Future.delayed(Duration(milliseconds: ecoWaitMs));
      } else {
        await Future.delayed(Duration.zero);
      }
      coolDownTimer.reset();
      yieldTimer.reset();
    } else if (yieldTimer.elapsedMilliseconds > 14) {
      await Future.delayed(Duration.zero);
      yieldTimer.reset();
    }

    if (X.isEmpty) return TreeNode(value: List.filled(outputSize, 0.0));

    bool allSame = true;
    for (int i = 1; i < Y.length; i++) {
      for (int j = 0; j < outputSize; j++) {
        if (Y[i][j] != Y[0][j]) {
          allSame = false;
          break;
        }
      }
      if (!allSame) break;
    }

    if (allSame || depth >= maxDepth) {
      return TreeNode(value: _calculateLeafValue(Y));
    }

    int bestFeature = -1;
    double bestThreshold = 0.0;
    double bestScore = double.infinity;
    List<List<double>> bestLeftX = [], bestLeftY = [];
    List<List<double>> bestRightX = [], bestRightY = [];

    int numFeatures = X[0].length;
    double currentScore = _calculateImpurity(Y);

    for (int f = 0; f < numFeatures; f++) {
      Set<double> uniqueVals = {};
      for (int i = 0; i < X.length; i++) uniqueVals.add(X[i][f]);

      if (uniqueVals.length <= 1) continue;

      List<double> sortedUnique = uniqueVals.toList()..sort();
      List<double> candidateThresholds = [];

      const int maxBins = 20;

      if (sortedUnique.length <= maxBins) {
        for (int tIdx = 0; tIdx < sortedUnique.length - 1; tIdx++) {
          candidateThresholds.add(
            (sortedUnique[tIdx] + sortedUnique[tIdx + 1]) / 2.0,
          );
        }
      } else {
        double step = sortedUnique.length / maxBins;
        for (int i = 1; i < maxBins; i++) {
          int idx = (i * step).floor();
          if (idx < sortedUnique.length - 1) {
            candidateThresholds.add(
              (sortedUnique[idx] + sortedUnique[idx + 1]) / 2.0,
            );
          }
        }
        candidateThresholds = candidateThresholds.toSet().toList();
      }

      for (double threshold in candidateThresholds) {
        List<List<double>> leftX = [], leftY = [];
        List<List<double>> rightX = [], rightY = [];

        for (int i = 0; i < X.length; i++) {
          if (X[i][f] <= threshold) {
            leftX.add(X[i]);
            leftY.add(Y[i]);
          } else {
            rightX.add(X[i]);
            rightY.add(Y[i]);
          }
        }

        if (leftX.isEmpty || rightX.isEmpty) continue;

        double score =
            (leftY.length * _calculateImpurity(leftY) +
                rightY.length * _calculateImpurity(rightY)) /
            Y.length;

        if (score < bestScore) {
          bestScore = score;
          bestFeature = f;
          bestThreshold = threshold;
          bestLeftX = leftX;
          bestLeftY = leftY;
          bestRightX = rightX;
          bestRightY = rightY;
        }
      }
    }
    if (bestFeature == -1) {
      return TreeNode(value: _calculateLeafValue(Y));
    }

    double scoreDecrease = currentScore - bestScore;
    if (scoreDecrease > 0) {
      featureImportances[bestFeature] += scoreDecrease * Y.length;
    }

    return TreeNode(
      featureIndex: bestFeature,
      threshold: bestThreshold,
      left: await _buildTree(
        bestLeftX,
        bestLeftY,
        depth + 1,
        featureImportances,
        ecoWaitMs,
        isCancelled,
        yieldTimer,
        coolDownTimer,
      ),
      right: await _buildTree(
        bestRightX,
        bestRightY,
        depth + 1,
        featureImportances,
        ecoWaitMs,
        isCancelled,
        yieldTimer,
        coolDownTimer,
      ),
    );
  }

  double _calculateImpurity(List<List<double>> Y) {
    if (Y.isEmpty) return 0.0;
    if (lossType == 1) {
      List<double> counts = List.filled(outputSize, 0.0);
      for (var y in Y) {
        int maxIdx = 0;
        double maxVal = y[0];
        for (int j = 1; j < y.length; j++) {
          if (y[j] > maxVal) {
            maxVal = y[j];
            maxIdx = j;
          }
        }
        counts[maxIdx]++;
      }
      double gini = 1.0;
      for (double count in counts) {
        double p = count / Y.length;
        gini -= p * p;
      }
      return gini;
    } else {
      List<double> mean = _calculateLeafValue(Y);
      double mse = 0.0;
      for (var y in Y) {
        for (int j = 0; j < y.length; j++) mse += pow(y[j] - mean[j], 2);
      }
      return mse / Y.length;
    }
  }

  List<double> _calculateLeafValue(List<List<double>> Y) {
    List<double> val = List.filled(outputSize, 0.0);
    if (Y.isEmpty) return val;
    for (var y in Y) {
      for (int j = 0; j < outputSize; j++) val[j] += y[j];
    }
    for (int j = 0; j < outputSize; j++) val[j] /= Y.length;

    return val;
  }

  TreePath predictPath(List<double> x) {
    TreeNode? node = root;
    List<int> route = [];
    while (node != null && node.value == null) {
      if (x[node.featureIndex!] <= node.threshold!) {
        route.add(0);
        node = node.left;
      } else {
        route.add(1);
        node = node.right;
      }
    }
    return TreePath(route, node?.value ?? List.filled(outputSize, 0.0));
  }
}

class RandomForest {
  final int numTrees;
  final int maxDepth;
  final int lossType;
  final int inputSize;
  final int outputSize;
  List<DecisionTree> trees = [];
  List<double> featureImportances = [];

  RandomForest({
    required this.numTrees,
    required this.maxDepth,
    required this.lossType,
    required this.inputSize,
    required this.outputSize,
  });

  Map<String, dynamic> toJson() => {
    'numTrees': numTrees,
    'maxDepth': maxDepth,
    'lossType': lossType,
    'inputSize': inputSize,
    'outputSize': outputSize,
    'trees': trees.map((t) => t.toJson()).toList(),
    'featureImportances': featureImportances,
  };

  factory RandomForest.fromJson(Map<String, dynamic> json) {
    var rf = RandomForest(
      numTrees: json['numTrees'] ?? 5,
      maxDepth: json['maxDepth'] ?? 3,
      lossType: json['lossType'] ?? 0,
      inputSize: json['inputSize'] ?? 1,
      outputSize: json['outputSize'] ?? 1,
    );
    if (json['trees'] != null) {
      rf.trees = List<DecisionTree>.from(
        json['trees'].map((x) => DecisionTree.fromJson(x)),
      );
    }
    if (json['featureImportances'] != null) {
      rf.featureImportances = List<double>.from(
        json['featureImportances'].map((x) => (x as num).toDouble()),
      );
    }
    return rf;
  }

  Future<void> train(
    List<List<double>> X,
    List<List<double>> Y,
    int ecoWaitMs,
    bool Function() isCancelled,
  ) async {
    if (lossType == 1 && Y.isNotEmpty && Y[0].isNotEmpty) {
      if ((Y[0].reduce((a, b) => a + b) - 1.0).abs() >= 0.01) {
        print(
          '\n'
          '=======================================================\n'
          '⚠️ [Hakoniwa AI - RF Engine WARNING]\n'
          'In classification mode (lossType == 1), the target data Y\n'
          'should be one-hot encoded vectors.\n'
          'Please ensure the data has passed through encodeData().\n'
          '=======================================================\n',
        );
      }
    }

    trees.clear();
    featureImportances = List.filled(inputSize, 0.0);
    Random rand = Random();

    Stopwatch yieldTimer = Stopwatch()..start();
    Stopwatch coolDownTimer = Stopwatch()..start();

    for (int i = 0; i < numTrees; i++) {
      if (isCancelled()) break;

      List<List<double>> sampleX = [];
      List<List<double>> sampleY = [];
      for (int j = 0; j < X.length; j++) {
        int idx = rand.nextInt(X.length);
        sampleX.add(X[idx]);
        sampleY.add(Y[idx]);
      }

      DecisionTree tree = DecisionTree(
        maxDepth: maxDepth,
        lossType: lossType,
        outputSize: outputSize,
      );

      await tree.train(
        sampleX,
        sampleY,
        featureImportances,
        ecoWaitMs,
        isCancelled,
        yieldTimer,
        coolDownTimer,
      );
      trees.add(tree);
    }

    double sumImportance = featureImportances.fold(0, (a, b) => a + b);
    if (sumImportance > 0) {
      for (int i = 0; i < featureImportances.length; i++) {
        featureImportances[i] /= sumImportance;
      }
    }
  }

  RFPrediction predict(List<double> x) {
    if (trees.isEmpty) return RFPrediction(List.filled(outputSize, 0.0), []);

    List<TreePath> paths = [];
    List<double> finalOutput = List.filled(outputSize, 0.0);

    for (var tree in trees) {
      TreePath path = tree.predictPath(x);
      paths.add(path);
      for (int j = 0; j < outputSize; j++) {
        finalOutput[j] += path.treeOutput[j];
      }
    }

    if (lossType == 1) {
      for (int j = 0; j < outputSize; j++) {
        finalOutput[j] /= numTrees;
      }
    } else {
      for (int j = 0; j < outputSize; j++) {
        finalOutput[j] /= numTrees;
      }
    }

    return RFPrediction(finalOutput, paths);
  }
}
