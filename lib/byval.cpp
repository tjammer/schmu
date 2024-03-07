#include <caml/alloc.h>
#include <llvm/IR/IRBuilder.h>

using namespace llvm;

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
}
