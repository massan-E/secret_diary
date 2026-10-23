class DiariesController < ApplicationController
  skip_forgery_protection # Step 5 の体験用。終わったら必ず消す
  before_action :set_diary, only: %i[ show edit update destroy ]

  # GET /diaries
  def index
    @diaries = current_user.diaries
  end

  # GET /diaries/1
  def show
  end

  # GET /diaries/new
  def new
    @diary = current_user.diaries.build
  end

  # GET /diaries/1/edit
  def edit
  end

  # POST /diaries
  def create
    @diary = current_user.diaries.build(diary_params)

    if @diary.save
      redirect_to @diary, notice: "Diary was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /diaries/1
  def update
    if @diary.update(diary_params)
      redirect_to @diary, notice: "Diary was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /diaries/1
  def destroy
    @diary.destroy!
    redirect_to diaries_path, notice: "Diary was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_diary
      @diary = current_user.diaries.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def diary_params
      params.expect(diary: [ :title, :body ])
    end
end
