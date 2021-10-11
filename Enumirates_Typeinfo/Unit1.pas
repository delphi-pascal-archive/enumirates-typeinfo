unit Unit1;
{Jean_Jean pour Delphifr

 Un Type Enum�r� peut avoir 4 milliards de valeurs tandis qu'un type Enum�r�
 utilis� dans un Ensemble ne peut avoir que 256 valeurs

 Or la fonction GetEnumName(TypeInfo, index) de l'unit� TypeInfo ne peut que
 donner la position d'un �l�ment de la liste qui lui est transmise.
 De plus, on ne peut pas concat�ner les listes d�num�r�s comme des ensembles,
 il faut trouver un autre m�canisme.

 C'est ce que je propose ici en concat�nant tous les �l�ments de toutes les liste
 dans un stringList. Cela permet de travailler sur l'ensemble des items de toutes
 les listes pr�d�finies

 Avec les Type Enum�r� (qui sont des scalaire, on peut �galement utiliser
 dans la liste d�finie les fonctions : Ord, Succ, Pred, Low et High!

 RTTI (TypInfo):

 Les fonctions sp�cifiques de la RTTI (Run-Time Type Information) existe depuis
 Delphi 2 mais n'ont �t� publi�es qu'avec Delphi 4 avec l'unit� TypInfo de Borland.
 La RTTI g�n�re des informations en provenance du compilateur et la documentation
 est peu fournie.
 Apparemment, Embarcadero place ces infos dans les API bien que les fonctions
 sont toujours d�finies dans System.TypInfo ...

 Les fonctions utilis�es ici sont :
                                    - GetEnumName
                                         avec sa structure TypeInfo
                                    - GetEnumValue
                                    - GetTypeData
                                         avec ses structures et pointeurs:
                                         PTypeData
                                         TTypeData
                                         TTypeKing
 La fonction GetTypeData est puissante car elle permet d'analyser des donn�es dont
 on ne conna�t pas � priori la nature. Un swich avec TTypeKing permet de traiter correctement les infos

 type TTypeKind = (tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat,
                   tkString, tkSet, tkClass, tkMethod, tkWChar, tkLString,
                   tkWString, tkVariant, tkArray, tkRecord, tkInterface,
                   tkInt64, tkDynArray, tkUString, tkClassRef, tkPointer,
                   tkProcedure);
 On utilise ici tkEnumeration mais je l'ai tester �galement sur quelques autres
 types d'infos sur les fiches entre autres.

}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, jpeg, ExtCtrls,TypInfo;

Type

  TEnum1 = (e11,e12,e13,e14,e15);
  TEnum2 = (e21,e22,e23);
  TEnum3 = (e31,e32,e33,e34,e35,e36,e37);

Const
  Card1  = Ord(High(tEnum1)) + 1;
  Card2  = Ord(High(tEnum2)) + 1;
  Card3  = Ord(High(tEnum3)) + 1;

  kEnum1 : array[0..Card1 - 1] of Char = ('A','G','R','E','A');
  kEnum2 : array[0..Card2 - 1] of Char = ('1','7','4');
  kEnum3 : array[0..Card3 - 1] of Char = ('&','+','*','@','?','#','�');

type
  TForm1 = class(TForm)
    Image1: TImage;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    MInfoEnumListes: TMemo;
    LBListes: TListBox;
    Bevel2: TBevel;
    Memo1: TMemo;
    ShSelect: TShape;
    LBListItems: TListBox;
    ShVerti: TShape;
    ShEtiquette2: TShape;
    LbEtiquette2: TLabel;
    ShEtiquette1: TShape;
    LbEtiquette1: TLabel;
    Lb1: TLabel;
    Lb2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LBListesClick(Sender: TObject);
    procedure LBListItemsClick(Sender: TObject);
    procedure LBListItemsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
    ListEnum : TStringList;
    nList    : Integer; // num�ro de liste courante dans s�lection d'un item global
    PosInEnum: Integer; // position de l'item dans la liste concern�e
    Procedure UpdateCouleursItemsListe;
    Procedure MAJAffichageSelection(Const nMaxItems : Integer);
    Procedure MAJAffichageItemDansListe(Const IndexAll : integer);
    Procedure MAJTraits(aLBIndex : integer);
  end;


Const
  OrgSel = 18; // pour la s�lection du sous-ensemble
  PasSel = 44;

Var
  Form1 : TForm1;

implementation
Uses Inifiles;
{$R *.dfm}

{Donne le nom de l'�l�ment de la liste � la position index sous forme de chaine}
Function EnumToStr(const TypeInfo: pTypeInfo; Index : Integer): string;
begin
  Result := GetEnumName(TypeInfo, index)
end;

{-------------------------------------------------------------------------------
 Donne le num�ro de liste selon la valeur la position de l'�l�ment dans l'ensemble
 des listes
-------------------------------------------------------------------------------}
Function IndexToNumList(Const aIndex : Integer): Integer;
Begin
  Case aIndex of
   1..Card1 : result := 1;
   Card1 + 1..Card1 + Card2: result := 2;
   Card1+ + Card2 + 1..Card1+Card2+Card3: result := 3;
   Else result := 0;
  end
End;

{-------------------------------------------------------------------------------
 Recherche la position de l'�l�ment chaine d'un TypeListe Enum�r� dans la liste
 concat�n�e des Listes d'�num�r�s
-------------------------------------------------------------------------------}
Function PosAllListOfTypeNameStr(Const aEle : String;aList : TStringList): integer;
 Var ii  : integer;
     Str : String;
Begin
  Result := -1;
  For ii := 0 to aList.Count - 1 do
  begin
    Str := aList[ii];
    if aEle = Copy(Str,1,Pos(' ',Str)-1) then
    begin
      Result := ii+1;
      Break;
    end
  end
End;

{-------------------------------------------------------------------------------
 Extrait la donn�e d'une des listes par sa s�lection dans la liste concat�n�e
 des lsites
-------------------------------------------------------------------------------}
Function ValueOfAllList(Const index : integer;aList : TStringList): String;
 Var P   : integer;
     Str : String;
Begin
  Result := '?';
  if index < aList.Count then
  begin
    Str := aList[index];
    P   := Pos(':',Str);
    Result := Copy(Str,P+2,Length(Str) - P);
  end
End;

{- Cr�ation fiche avec affichage initial --------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
 var ii, pos  : integer;
begin
  {Position d�part Shape et labels s�lection}
  With ShSelect do
  begin
    Visible := False;
    Width   :=  46;
    Height  :=  46;
    Left    := OrgSel;
    Top     :=  71;
  end;
  With ShVerti do
  begin
    Width    :=   5;
    Height   := 254;
    Left     := 425;
    Top      := 113;
  end;
  With ShEtiquette1 do
  begin
    Width  :=  64;
    Height :=  23;
    Left   := 398;
    Top    := 298;
  end;
  With ShEtiquette2 do
  begin
    Width  :=  64;
    Height :=  23;
    Left   := 398;
    Top    := 364;
  end;
  With LbEtiquette1 do
  begin
    Width  :=  64;
    Height :=  23;
    Left   := 398;
    Top    := 298;
  end;
  With LbEtiquette2 do
  begin
    Width  :=  64;
    Height :=  23;
    Left   := 398;
    Top    := 364;
  end;

  {Affichages cardinalit�s}
  StaticText2.Caption := inttostr(Card1);
  StaticText3.Caption := inttostr(Card2);
  StaticText4.Caption := inttostr(Card3);


  {1. Cr�ation Liste des Listes et Affichage dans ListBox}
  lbListes.Clear;
  with lbListes.Items do
  begin
    AddObject('Liste TEnum 1', TypeInfo(TEnum1)) ;
    AddObject('Liste TEnum 2', TypeInfo(TEnum2)) ;
    AddObject('Liste TEnum 3', TypeInfo(TEnum3)) ;
  end;

  ListEnum := TStringList.Create;
  MInfoEnumListes.Clear;

  {Cr�ation d'une liste unique des listes d'�num�r�s}
  For ii := Ord(Low(TEnum1)) to Ord(High(TEnum1)) do
      ListEnum.Add(GetEnumName(TypeInfo(TEnum1),ii)+' : '+kEnum1[ii]);
  For ii := Ord(Low(TEnum2)) to Ord(High(TEnum2)) do
      ListEnum.Add(GetEnumName(TypeInfo(TEnum2),ii)+' : '+kEnum2[ii]);
  For ii := Ord(Low(TEnum3)) to Ord(High(TEnum3)) do
      ListEnum.Add(GetEnumName(TypeInfo(TEnum3),ii)+' : '+kEnum3[ii]);

  {Affichage liste dans ListBox}
  LBListItems.Clear;
  For ii := 0 to ListEnum.Count - 1 do
      LBListItems.Items.Add(ListEnum[ii]);

  {calcul des positions (globale et interne au type d'un �l�ment pr�-s�lectionn�}
  Pos   := PosAllListOfTypeNameStr('e32',ListEnum);
  PosInEnum := GetEnumValue(TypeInfo(TEnum3),'e32');
  nList := 3;
  MAJAffichageItemDansListe(Pos-1);
  MAJTraits(Pos-1);

  nList := 0; // pas eu encore de s�lection de liste dans la liste des items
end;

{- Destruction fiche avec destruction liste ----------------------------------}
procedure TForm1.FormDestroy(Sender: TObject);
begin
  ListEnum.Free;
end;

{- Met � jour la s�lection des �l�ments de l'image ----------------------------}
Procedure TForm1.MAJAffichageSelection(Const nMaxItems : Integer);
Begin
  Case LbListes.ItemIndex of
  0 : ShSelect.Left:= OrgSel;
  1 : ShSelect.Left:= OrgSel + Card1 * PasSel - nMaxItems - 2;
  2 : ShSelect.Left:= OrgSel + (Card1 + Card2) * PasSel - nMaxItems - 2;
  end;
  ShSelect.Width   := PasSel + (nMaxItems * PasSel) - nMaxItems + 1;
End;

{- Met � jour l'�tiquette 1 : nom de l'item et position dans sa liste ---------}
Procedure TForm1.MAJAffichageItemDansListe(Const IndexAll : integer);
  var TypeNameStr : String;
Begin
  Case nList of
   1: begin
        TypeNameStr := EnumToStr(TypeInfo(TEnum1),IndexAll);
        PosInEnum   := GetEnumValue(TypeInfo(TEnum1),TypeNameStr) + 1;
        LBEtiquette1.Caption := TypeNameStr+' en '+ Inttostr(PosInEnum)+ ' / '+inttostr(Card1);
      end;
   2: begin
        TypeNameStr := EnumToStr(TypeInfo(TEnum2),IndexAll - Card1);
        PosInEnum   := GetEnumValue(TypeInfo(TEnum2),TypeNameStr) + 1;
        LBEtiquette1.Caption := TypeNameStr+' en '+ Inttostr(PosInEnum)+ ' / '+inttostr(Card2);
      end;
   3: begin
        TypeNameStr := EnumToStr(TypeInfo(TEnum3),IndexAll - Card1 - Card2);
        PosInEnum   := GetEnumValue(TypeInfo(TEnum3),TypeNameStr) + 1;
        LBEtiquette1.Caption := TypeNameStr+' en '+ Inttostr(PosInEnum)+ ' / '+inttostr(Card3);
      end;
   end
End;


{- Positionne les traits et l'�tiquette de l'�l�ment s�lectionn� --------------}
Procedure TForm1.MAJTraits(aLBIndex : integer);
Begin
  ShVerti.Left      := OrgSel + PasSel div 2 + aLBIndex * PasSel - aLBIndex - 2;
  ShEtiquette1.Left := ShVerti.Left - ShEtiquette2.Width div 2;
  ShEtiquette2.Left := ShEtiquette1.Left;
  Lb1.Left          := ShEtiquette1.Left - 13;
  Lb2.Left          := ShEtiquette2.Left - 13;
  LbEtiquette1.Left := ShEtiquette1.Left;
  LbEtiquette2.Left := ShEtiquette1.Left;
  LbEtiquette2.Caption := '"'+ValueOfAllList(aLBIndex,ListEnum)+'" en '+ inttostr(aLBIndex+1)
                       + ' / '+inttostr(Card1 + Card2 + Card3);
end;

{-------------------------------------------------------------------------------
 Choix d'une liste �num�r�e particuli�re, Permet =>
 - La d�terminantion du pointeur vers le type d'objet
 - L'identification du type s�lectionn� et les
   informations le concernant
-------------------------------------------------------------------------------}
procedure TForm1.LBListesClick(Sender: TObject);
 var
   PtrTypeInfo: PTypeInfo;
   PtrTypeData: PTypeData;
   TypeNameStr: string;
   TypeKindStr: string;
   MinVal,
   MaxVal,
   index      : Integer;
begin
  With LbListes do
  begin
    {1. D�termine la r�f�rence de classe TTypeInfo de l'objet concern�}
    PtrTypeInfo := PTypeInfo(Items.Objects[ItemIndex]) ;

    {2. D�termine l'adresse des informations sur TTypeData}
    PtrTypeData := GetTypeData(PtrTypeInfo) ;

    {3. Donne le nom du type en version chaine}
    TypeNameStr := PtrTypeInfo.Name;

    {4. Donne le nom du param�tre de type TTypeKind en version chaine}
    TypeKindStr := GetEnumName(TypeInfo(TTypeKind), Integer(PtrTypeInfo^.Kind)) ;

    {5. Donne les mini et maxi des index des valeurs du type}
    MinVal := PtrTypeData^.MinValue;
    MaxVal := PtrTypeData^.MaxValue;

    {6. Ecrit les infos dans le m�mo}
    MInfoEnumListes.Clear;
    with MInfoEnumListes.Lines do
    begin
      {6.1 Infos g�n�rales}
      Add('Type Name: ' + TypeNameStr) ;
      Add('Type Kind: ' + TypeKindStr) ;
      Add('Min Val  : ' + IntToStr(MinVal)) ;
      Add('Max Val  : ' + IntToStr(MaxVal)) ;

      {6.2 Valeurs et noms des types �num�r�s}
      if PtrTypeInfo^.Kind = tkEnumeration then
         for index := MinVal to MaxVal do
         Add(Format(' Valeur: %d Nom: %s', [index, GetEnumName(PtrTypeInfo, index)])) ;
    end;
  end;

  {7. Affichage de la s�lection sur le graphique}
  ShSelect.Visible := True;
  MAJAffichageSelection(MaxVal);

end;

{-------------------------------------------------------------------------------
 Clic sur les pastilles grises => D�termination de la position d'un �l�ment
 d'une des listes dans l'ensemble
 remarque   : Le choix d'un �l�ment met � jour les autres affichages :
              Listbox des listes �num�r�es
              Memo des infos sur la liste
-------------------------------------------------------------------------------}
procedure TForm1.LBListItemsClick(Sender: TObject);
begin
  {Identification de la liste}
  nList := IndexToNumList(LBListItems.ItemIndex +1);

  Case nList of
   1 : begin
       LBListes.ItemIndex := nList -1;
       MAJAffichageSelection(Card1 - 1);
     end;
   2 : begin
       LBListes.ItemIndex := nList -1;
       MAJAffichageSelection(Card2 - 1);
     end;
   3 : begin
       LBListes.ItemIndex := nList -1;
       MAJAffichageSelection(Card3 - 1);
     end;
  end;

  {MAJ Affichages}
  MAJAffichageItemDansListe(LBListItems.ItemIndex);
  LBListesClick(Self);
  UpdateCouleursItemsListe;
  MAJTraits(LBListItems.ItemIndex);

end;

{- G�re les couleurs de la liste des items ------------------------------------}
procedure TForm1.LBListItemsDrawItem(Control: TWinControl; Index: Integer;
                                     Rect: TRect; State: TOwnerDrawState);
var
  RowColor  : TColor;
  ListBrush : TBrush;
  IndexMin,
  IndexMax  : Integer;
begin
  ListBrush := TBrush.Create; // Brush pour couleur de fond

  with (Control as TListBox).Canvas do
  begin

    {d�termination des lignes de l'ensemble concern�}
    Case nList of
     1 : begin IndexMin := 0; IndexMax := Card1 -1; end;
     2 : begin IndexMin := Card1; IndexMax := Card1 + Card2 -1; end;
     3 : begin IndexMin := Card1 + Card2; IndexMax := Card1 + Card2 + Card3 -1; end;
     else begin IndexMin := 0; IndexMax := 0; end;
    End;

    {d�termination de la couleur des lignes}
    if (index > IndexMin-1) AND (index < IndexMax+1) then
    begin
      RowColor   := clBlack;
      Font.Color := clBlack;
      Font.Style := [fsBold];
    end else
    begin
      RowColor := clWhite;
      Font.Color := clBlack;
      Font.Style := [];
    end;

    ListBrush.Style := bsSolid;
    ListBrush.Color := RowColor;
    Windows.FillRect(Handle, Rect, ListBrush.Handle);
    Brush.Style := bsClear;

    {�criture de l'item}
    if (index > IndexMin-1) AND (index < IndexMax+1)
    then if index = LbListItems.ItemIndex
         then Font.Color := clYellow
         else Font.Color := clWhite
    else Font.Color := clBlack;
    TextOut(Rect.Left, Rect.Top, (Control as TListBox).Items[index]);
    ListBrush.Free
  end

end;

{- Met � jour les couleurs de la liste des items ------------------------------}
Procedure TForm1.UpdateCouleursItemsListe;
 var ii : integer;
begin
  For ii:=0 to LBListItems.Items.Count-1 do
    LBListItemsDrawItem(LBListItems,ii,LBListItems.ItemRect(ii),[odDefault])
End;


end.
