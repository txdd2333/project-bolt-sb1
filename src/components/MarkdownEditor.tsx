import { useState, useEffect, useRef } from 'react';
import { Editor, Toolbar } from '@wangeditor/editor-for-react';
import { IDomEditor, IEditorConfig, IToolbarConfig } from '@wangeditor/editor';
import { authService, storageService } from '../services';

interface MarkdownEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

type InsertFnType = (url: string, alt?: string, href?: string) => void;

export default function MarkdownEditor({ value, onChange, placeholder }: MarkdownEditorProps) {
  const [editor, setEditor] = useState<IDomEditor | null>(null);
  const isInternalUpdate = useRef(false);

  const toolbarConfig: Partial<IToolbarConfig> = {
    toolbarKeys: [
      'undo',
      'redo',
      '|',
      'headerSelect',
      'fontFamily',
      'fontSize',
      '|',
      'bold',
      'italic',
      'underline',
      'through',
      'sub',
      'sup',
      'clearStyle',
      '|',
      'color',
      'bgColor',
      '|',
      'indent',
      'delIndent',
      'justifyLeft',
      'justifyCenter',
      'justifyRight',
      'justifyJustify',
      '|',
      'lineHeight',
      '|',
      'bulletedList',
      'numberedList',
      'todo',
      '|',
      'blockquote',
      'emotion',
      'insertLink',
      {
        key: 'group-image',
        title: '图片',
        iconSvg: '<svg viewBox="0 0 1024 1024"><path d="M959.877 128l0.123 0.123v767.775l-0.123 0.122H64.102l-0.122-0.122V128.123l0.122-0.123h895.775zM960 64H64C28.795 64 0 92.795 0 128v768c0 35.205 28.795 64 64 64h896c35.205 0 64-28.795 64-64V128c0-35.205-28.795-64-64-64zM832 288.01c0 53.023-42.988 96.01-96.01 96.01s-96.01-42.987-96.01-96.01S682.967 192 735.99 192 832 234.988 832 288.01zM896 832H128V704l224.01-384 256 320h64l224.01-192z"></path></svg>',
        menuKeys: ['uploadImage', 'insertImage'],
      },
      {
        key: 'group-video',
        title: '视频',
        iconSvg: '<svg viewBox="0 0 1024 1024"><path d="M981.184 160.096C837.568 139.456 678.848 128 512 128S186.432 139.456 42.816 160.096C15.296 267.808 0 386.848 0 512s15.264 244.16 42.816 351.904C186.464 884.544 345.152 896 512 896s325.568-11.456 469.184-32.096C1008.704 756.192 1024 637.152 1024 512s-15.264-244.16-42.816-351.904zM384 704V320l320 192-320 192z"></path></svg>',
        menuKeys: ['uploadVideo', 'insertVideo'],
      },
      'insertTable',
      'codeBlock',
      'divider',
      '|',
      'fullScreen',
    ],
  };

  const editorConfig: Partial<IEditorConfig> = {
    placeholder: placeholder || '请输入文档内容...',
    MENU_CONF: {
      uploadImage: {
        async customUpload(file: File, insertFn: InsertFnType) {
          try {
            const user = await authService.getCurrentUser();
            if (!user) {
              alert('请先登录后再上传图片');
              return;
            }

            const fileExt = file.name.split('.').pop();
            const fileName = `${Date.now()}-${Math.random().toString(36).substring(2, 9)}.${fileExt}`;
            const filePath = `${user.id}/${fileName}`;

            const { error: uploadError } = await storageService.upload('sop-images', filePath, file);

            if (uploadError) {
              console.error('Upload error:', uploadError);
              alert('图片上传失败，请重试');
              return;
            }

            const publicUrl = storageService.getPublicUrl('sop-images', filePath);

            insertFn(publicUrl, file.name, '');
          } catch (error) {
            console.error('Upload error:', error);
            alert('图片上传失败，请重试');
          }
        },
      },
      uploadVideo: {
        customUpload(_file: File, _insertFn: (url: string, poster?: string) => void) {
          alert('视频上传功能暂未开放，请使用插入视频链接功能');
        },
      },
      fontFamily: {
        fontFamilyList: [
          '黑体',
          '仿宋',
          '楷体',
          '宋体',
          '微软雅黑',
          'Arial',
          'Tahoma',
          'Verdana',
          'Times New Roman',
          'Courier New',
        ],
      },
      fontSize: {
        fontSizeList: [
          '12px',
          '14px',
          '16px',
          '18px',
          '20px',
          '24px',
          '28px',
          '32px',
          '36px',
          '48px',
        ],
      },
      lineHeight: {
        lineHeightList: ['1', '1.15', '1.5', '1.75', '2', '2.5', '3'],
      },
    },
  };

  useEffect(() => {
    if (editor && !isInternalUpdate.current) {
      const currentHtml = editor.getHtml();
      if (currentHtml !== value) {
        editor.setHtml(value || '<p></p>');
      }
    }
    isInternalUpdate.current = false;
  }, [value, editor]);

  useEffect(() => {
    return () => {
      if (editor) {
        editor.destroy();
      }
    };
  }, [editor]);

  const handleChange = (newEditor: IDomEditor) => {
    const html = newEditor.getHtml();
    if (html !== value) {
      isInternalUpdate.current = true;
      onChange(html);
    }
  };

  return (
    <div className="h-full flex flex-col border border-gray-200 rounded-lg overflow-hidden bg-white">
      <Toolbar
        editor={editor}
        defaultConfig={toolbarConfig}
        mode="default"
        className="border-b border-gray-200"
      />
      <div className="flex-1 overflow-auto">
        <Editor
          defaultConfig={editorConfig}
          value={value}
          onCreated={setEditor}
          onChange={handleChange}
          mode="default"
          className="h-full"
        />
      </div>
    </div>
  );
}
