import SwiftUI
import PhotosUI

struct AddWordView: View {
    @StateObject private var viewModel = AddWordViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showManualInput = false
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppLayout.cardSpacing) {
                    // 添加方式选择
                    AddMethodSection(
                        onCameraTap: { showCamera = true },
                        onPhotoTap: { showPhotoPicker = true },
                        onManualTap: { showManualInput = true }
                    )
                    
                    // 已选图片
                    if !viewModel.selectedImages.isEmpty {
                        SelectedImagesSection(
                            images: viewModel.selectedImages,
                            onRemove: { index in viewModel.removeImage(at: index) }
                        )
                    }
                    
                    // 识别结果
                    if viewModel.isProcessing {
                        ProcessingView()
                    } else if !viewModel.wordDetails.isEmpty {
                        RecognizedWordsSection(
                            words: $viewModel.wordDetails,
                            onToggle: { index in viewModel.toggleWordSelection(at: index) },
                            onUpdateDefinition: { index, definition in
                                viewModel.updateWordDetail(at: index, definition: definition)
                            }
                        )
                    }
                    
                    // 保存按钮
                    if !viewModel.wordDetails.isEmpty && !viewModel.isProcessing {
                        Button(action: { viewModel.saveSelectedWords() }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("添加到词库 (\(viewModel.wordDetails.filter { $0.isSelected }.count) 个)")
                            }
                            .primaryButtonStyle()
                        }
                        .disabled(viewModel.wordDetails.filter { $0.isSelected }.isEmpty)
                        .opacity(viewModel.wordDetails.filter { $0.isSelected }.isEmpty ? 0.5 : 1)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.verticalPadding)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("添加单词")
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay(
                Group {
                    if viewModel.showSuccessMessage {
                        SuccessToast()
                    }
                }
            )
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    viewModel.addImage(image)
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.addImage(image)
                            }
                        }
                    }
                    selectedItems = []
                }
            }
            .sheet(isPresented: $showManualInput) {
                ManualInputView { text, definition in
                    viewModel.addManualWord(text: text, definition: definition)
                }
            }
        }
    }
}

// MARK: - 添加方式选择
struct AddMethodSection: View {
    let onCameraTap: () -> Void
    let onPhotoTap: () -> Void
    let onManualTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            Text("添加方式")
                .font(AppFonts.subtitle)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppLayout.cardSpacing) {
                AddMethodButton(
                    icon: "camera.fill",
                    title: "拍照",
                    color: AppColors.primary,
                    action: onCameraTap
                )
                
                AddMethodButton(
                    icon: "photo.fill",
                    title: "相册",
                    color: AppColors.secondary,
                    action: onPhotoTap
                )
                
                AddMethodButton(
                    icon: "keyboard",
                    title: "手动输入",
                    color: AppColors.accent,
                    action: onManualTap
                )
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct AddMethodButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 已选图片
struct SelectedImagesSection: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            HStack {
                Text("已选图片")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(images.count) 张")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.smallSpacing) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(AppLayout.smallCornerRadius)
                            
                            Button(action: { onRemove(index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }
                }
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

// MARK: - 处理中视图
struct ProcessingView: View {
    var body: some View {
        VStack(spacing: AppLayout.componentPadding) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在识别图片中的英文...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppLayout.componentPadding * 2)
        .cardStyle()
    }
}

// MARK: - 识别结果
struct RecognizedWordsSection: View {
    @Binding var words: [AddWordViewModel.WordDetail]
    let onToggle: (Int) -> Void
    let onUpdateDefinition: (Int, String) -> Void
    
    var selectedCount: Int {
        words.filter { $0.isSelected }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallSpacing) {
            HStack {
                Text("识别结果")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    let allSelected = words.allSatisfy { $0.isSelected }
                    for i in 0..<words.count {
                        words[i].isSelected = !allSelected
                    }
                }) {
                    Text(selectedCount == words.count ? "取消全选" : "全选")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
            
            Text("已识别到 \(words.count) 个英文单词，选择要添加的单词")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(Array(words.enumerated()), id: \.element.id) { index, wordDetail in
                WordDetailRow(
                    wordDetail: wordDetail,
                    onToggle: { onToggle(index) },
                    onDefinitionChange: { definition in
                        onUpdateDefinition(index, definition)
                    }
                )
                
                if index < words.count - 1 {
                    Divider()
                }
            }
        }
        .padding(AppLayout.componentPadding)
        .cardStyle()
    }
}

struct WordDetailRow: View {
    let wordDetail: AddWordViewModel.WordDetail
    let onToggle: () -> Void
    let onDefinitionChange: (String) -> Void
    
    @State private var isEditing = false
    @State private var definition: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // 选择按钮
            Button(action: onToggle) {
                Image(systemName: wordDetail.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(wordDetail.isSelected ? AppColors.primary : AppColors.textSecondary)
                    .font(.title2)
            }
            
            // 单词信息
            VStack(alignment: .leading, spacing: 4) {
                Text(wordDetail.text)
                    .font(AppFonts.body.bold())
                    .foregroundColor(AppColors.textPrimary)
                
                if isEditing {
                    TextField("输入释义（可选）", text: $definition)
                        .font(AppFonts.caption)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            onDefinitionChange(definition)
                            isEditing = false
                        }
                } else {
                    HStack {
                        Text(wordDetail.definition.isEmpty ? "点击添加释义" : wordDetail.definition)
                            .font(AppFonts.caption)
                            .foregroundColor(wordDetail.definition.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                        
                        Button(action: {
                            definition = wordDetail.definition
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            definition = wordDetail.definition
        }
    }
}

// MARK: - 成功提示
struct SuccessToast: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                
                Text("单词已添加到词库")
                    .font(AppFonts.body.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(AppColors.secondary)
            .cornerRadius(AppLayout.largeCornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: true)
    }
}

// MARK: - 手动输入视图
struct ManualInputView: View {
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var wordText = ""
    @State private var definition = ""
    
    var isValid: Bool {
        !wordText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("单词") {
                    TextField("输入英文单词", text: $wordText)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Section("释义（可选）") {
                    TextField("输入中文释义", text: $definition)
                }
            }
            .navigationTitle("手动添加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(wordText.trimmingCharacters(in: .whitespaces), definition)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 相机视图
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddWordView()
}
