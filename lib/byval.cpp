#include <caml/alloc.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm-c/DebugInfo.h>

using namespace llvm;

#define DIBuilder_val(v) (*(LLVMDIBuilderRef *)(Data_custom_val(v)))
#define Value_val(v) ((LLVMMetadataRef)from_val(v))

// Thank you, zig
extern "C"
{
  extern void* from_val(value);

  void LlvmAddByvalAttr(value fn_val, value argnum, value type_val)
  {
    auto        fn_ref = (LLVMValueRef)from_val(fn_val);
    Function*   func   = unwrap<Function>(fn_ref);
    AttrBuilder attr_builder(func->getContext());
    auto        type_ref  = (LLVMTypeRef)from_val(type_val);
    Type*       llvm_type = unwrap<Type>(type_ref);
    attr_builder.addByValAttr(llvm_type);
    func->addParamAttrs(static_cast<unsigned>((argnum >> 1) - 1), attr_builder);
  }

  void LlvmFinalizeSp(value builder, value sp)
  {
    LLVMDIBuilderFinalizeSubprogram(DIBuilder_val(builder), Value_val(sp));
  }
}
